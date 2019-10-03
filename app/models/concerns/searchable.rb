module Searchable
  # Associations that are used on the index pages. Eager load them to prevent N+1 queries.
  EAGER_LOADABLE = [:content_provider, :ontology_term_links, :edit_suggestion, :materials, :events,
                    :training_coordinators].freeze

  extend ActiveSupport::Concern

  class_methods do
    def facet_keys
      @facet_keys ||= (facet_fields | Facets.special) # Memoize things like this so we don't have to recompute in each request.
    end

    # Allows multiple of the same param, i.e. operations=bla foo operations[]=foo&operations[]=bar
    def facet_keys_with_multiple
      @facet_keys_with_multiple ||= (facet_keys | facet_keys.map { |key| { key => [] } })
    end

    def search_and_facet_keys
      @search_and_facet_keys ||= ([:q] | facet_keys_with_multiple)
    end

    def search_and_filter(user, search_params = '', selected_facets = {}, page: 1, sort_by: nil, per_page: 30)
      includes = Searchable::EAGER_LOADABLE.select { |a| reflections.key?(a.to_s) }
      search(include: includes) do
        fulltext search_params
        # Set the search parameter
        # Disjunction clause
        active_facets = {}

        normal_facets = selected_facets.except(*Facets.special)

        any do
          # Set all facets
          normal_facets.each do |facet_title, facet_value|
            any do # Conjunction clause
              # Add to array that get executed lower down
              active_facets[facet_title] ||= []
              val = Facets.process(facet_title, facet_value)
              active_facets[facet_title] << with(facet_title, val)
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
            when 'Material'
              order_by(:created_at, :desc)
            else
              order_by(:sort_title, :asc)
          end
        end

        paginate page: page, per_page: per_page unless page.nil?

        Facets.special.each do |facet_title|
          if Facets.applicable?(facet_title, name)
            facet_value = Facets.process(facet_title, selected_facets[facet_title])
            Facets.send(facet_title.to_sym, self, facet_value)
          end
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

        facet_fields.each do |ff|
          facet ff, exclude: active_facets[ff]
        end

        if method_defined?(:user_requires_approval?)
          # Hide shadowbanned users' events, except from other shadowbanned users and administrators
          unless user && (user.shadowbanned? || user.is_admin?)
            without(:shadowbanned, true)
          end

          # Hide unverified/rejected users' things, except from curators and admins
          unless user && (user.is_curator? || user.is_admin?)
            without(:unverified, true)
          end
        end

        # Hide records the urls of which are failing
        if method_defined?(:link_monitor)
          unless user && user.is_admin?
            without(:failing, true)
          end
        end
      end
    end
  end

  def failing?
    if respond_to?(:link_monitor)
      return false if link_monitor.nil?
      return link_monitor.failing?
    end
    false
  end
end
