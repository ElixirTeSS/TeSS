module Facets
  SPECIAL = {
      include_expired: ['Event'],
      days_since_scrape: ['Event', 'Material', 'ContentProvider'],
      elixir: ['Event', 'Material', 'ContentProvider'],
      max_age: ['Event', 'Material']
  }.with_indifferent_access.freeze

  CONVERSIONS = {
      online: -> (value) { value == 'true' },
      include_expired: -> (value) { value == 'true'},
      max_age: -> (value) { Subscription::FREQUENCY.detect { |f| f[:title] == value }.try(:[], :period) }
  }

  class << self
    def process(facet, value)
      if CONVERSIONS[facet.to_sym]
        CONVERSIONS[facet.to_sym].call(value)
      else
        value
      end
    end

    def special
      SPECIAL.keys.map(&:to_s)
    end

    def applicable?(facet, class_name)
      SPECIAL.key?(facet) && SPECIAL[facet].include?(class_name)
    end

    def max_age(scope, age)
      return if age.blank?
      sunspot_scoped(scope) do
        with(:created_at).greater_than(age.ago)
      end
    end

    def include_expired(scope, value)
      sunspot_scoped(scope) { with('end').greater_than(Time.zone.now) } unless value
    end

    def days_since_scrape(scope, days)
      sunspot_scoped(scope) { with(:last_scraped).less_than(days.to_i.days.ago) } if days.present?
    end

    def elixir(scope, value)
      return if value.blank?
      sunspot_scoped(scope) do
        if value == 'true'
          any_of do
            with(:node, Node.pluck(:title))
            with(:content_provider, 'ELIXIR')
          end
        else
          without(:node, Node.pluck(:title))
        end
      end
    end

    def sunspot_scoped(sunspot_scope, &block)
      sunspot_scope.instance_eval(&block)
    end
  end
end
