module Searchable

  # Associations that are used on the index pages. Eager load them to prevent N+1 queries.
  EAGER_LOADABLE = [:content_provider, :scientific_topic_links, :edit_suggestion, :materials, :events,
                    :training_coordinators].freeze

  extend ActiveSupport::Concern

  class_methods do
    def search_and_filter(user, search_params = '', selected_facets = [], page: 1, sort_by: nil, per_page: 30, max_age: nil)
      includes = Searchable::EAGER_LOADABLE.select { |a| reflections.key?(a.to_s) }
      search(include: includes) do
        fulltext search_params
        # Set the search parameter
        # Disjunction clause
        active_facets = {}

        any do
          # Set all facets
          selected_facets.each do |facet_title, facet_value|
            next if %w(include_expired days_since_scrape elixir max_age).include?(facet_title)
            any do # Conjunction clause
              # Convert 'true' or 'false' to boolean true or false
              if facet_title == 'online'
                facet_value = if facet_value && (facet_value == 'true')
                                true
                              else
                                false
                              end
              end

              # Add to array that get executed lower down
              active_facets[facet_title] ||= []
              active_facets[facet_title] << with(facet_title, facet_value)
            end
          end
        end

        if sort_by && sort_by != 'default'
          case sort_by
            when 'early'
              # Sort by start date asc
              order_by(:start, :asc)
            when 'late'
              # Sort by start date desc
              order_by(:start, :desc)
            when 'rel'
              # Sort by relevance
            when 'mod'
              # Sort by last modified
              order_by(:updated_at, :desc)
            when 'new'
              # Sort by newest
              order_by(:created_at, :desc)
            else
              order_by(:sort_title, sort_by.to_sym)
          end
          # Defaults
        else
          case name
            when 'Event'
              order_by(:start, :asc)
            when 'ContentProvider'
              order_by(:count, :desc)
            else
              order_by(:sort_title, :asc)
          end
        end

        paginate page: page, per_page: per_page if !page.nil? && (page != '1')

        # Go through the selected facets and apply them and their facet_values
        if name == 'Event'
          unless selected_facets.keys.include?('include_expired') && (selected_facets['include_expired'] == true)
            with('end').greater_than(Time.zone.now)
          end
        end
        if ['Event', 'Material', 'ContentProvider'].include?(name) and selected_facets.keys.include?('elixir')
          if selected_facets['elixir']
            any_of do
              with(:node, Node.all.map{|x| x.title})
              with(:content_provider, 'ELIXIR')
            end
          else
            without(:node, Node.all.map{|x| x.title})
          end
        end
        if selected_facets.keys.include?('days_since_scrape')
          with(:last_scraped).less_than(selected_facets['days_since_scrape'].to_i.days.ago)
        end

        if attribute_method?(:public) && !(user && user.is_admin?) # Find a better way of checking this
          any_of do
            with(:public, true)
            with(:user_id, user.id) if user
            if attribute_method?(:collaborators)
              with(:collaborator_ids, user.id) if user
            end
          end
        end

        if max_age.present?
          with(:created_at).greater_than(max_age.ago)
        end

        facet_fields.each do |ff|
          facet ff, exclude: active_facets[ff]
        end
      end
    end
  end
end
