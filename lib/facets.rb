module Facets
  SPECIAL = {
      include_expired: -> (c) { c.name == 'Event' },
      include_archived: -> (c) { c.name == 'Material' },
      days_since_scrape: -> (c) { c.method_defined?(:last_scraped) },
      elixir: -> (c) { ['Event', 'Material', 'ContentProvider'].include?(c.name) },
      max_age: -> (c) { ['Event', 'Material'].include?(c.name) },
      start: -> (c) { c.name == 'Event' },
      running_during: -> (c) { c.name == 'Event' },
      include_hidden: -> (c) { c.method_defined?(:user_requires_approval?) }
  }.with_indifferent_access.freeze

  CONVERSIONS = {
      online: -> (value) { value == 'true' },
      include_expired: -> (value) { value == 'true'},
      include_archived: -> (value) { value == 'true'},
      max_age: -> (value) { Subscription::FREQUENCY.detect { |f| f[:title] == value }.try(:[], :period) },
      start: -> (value) { value&.split('/')&.map {|d| Date.parse(d) rescue nil } },
      running_during: -> (value) { value&.split('/')&.map {|d| Date.parse(d) rescue nil } },
      include_hidden: -> (value) { value == 'true'}
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

    def applicable?(facet, klass)
      SPECIAL.key?(facet) && SPECIAL[facet].call(klass)
    end

    def max_age(scope, age, _)
      return if age.blank?
      sunspot_scoped(scope) do
        with(:created_at).greater_than(age.ago)
      end
    end

    def start(scope, bounds, _)
      lb, ub = bounds

      sunspot_scoped(scope) do
        if lb && ub
          with(:start).between(lb..ub)
        elsif lb
          with(:start).greater_than_or_equal_to(lb)
        elsif ub
          with(:start).less_than_or_equal_to(ub)
        end
      end
    end

    def running_during(scope, bounds, _)
      lb, ub = bounds

      sunspot_scoped(scope) do
        if lb && ub
          with(:end).between(lb..(ub + TeSS::Config.site.fetch(:calendar_event_maxlength, 5).to_i.days))
        elsif lb
          with(:end).greater_than_or_equal_to(lb)
        elsif ub
          with(:start).less_than_or_equal_to(ub)
        end
      end
    end

    def include_expired(scope, value, _)
      sunspot_scoped(scope) { with('end').greater_than(Time.zone.now) } unless value
    end

    def include_archived(scope, value, _)
      return if value
      label = MaterialStatusDictionary.instance.lookup_value('archived', 'title')
      sunspot_scoped(scope) { without(:status, label) } if label
    end

    def include_hidden(scope, value, user)
      sunspot_scoped(scope) do
        # Hide shadowbanned users' events, except from other shadowbanned users and administrators
        unless user && (user.shadowbanned? || (user.is_admin? && value))
          without(:shadowbanned, true)
        end

        # Hide unverified/rejected users' things, except from curators and admins
        unless user && ((user.is_curator? || user.is_admin?) && value)
          without(:unverified, true)
        end
      end
    end

    def days_since_scrape(scope, days, _)
      sunspot_scoped(scope) { with(:last_scraped).less_than(days.to_i.days.ago) } if days.present?
    end

    def elixir(scope, value, _)
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
