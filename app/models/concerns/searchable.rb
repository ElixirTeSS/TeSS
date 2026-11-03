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

    # Searches and filters resources of the including model using Solr (via Sunspot),
    # applying space-based visibility, facets, sorting and pagination in a single query.
    #
    # Space filtering is applied before any other constraint: if +space+ is a specific
    # (non-default) space, only resources belonging to that space are returned; on the
    # default space, resources belonging to private spaces that are inaccessible to
    # +user+ are excluded via a Solr +without+ clause, leaving default-space resources
    # (those with no +space_id+) visible by default.
    #
    # user::             The currently authenticated user, or +nil+ for anonymous requests.
    #                    Used to determine which private spaces are accessible and to scope
    #                    ownership/collaboration facets.
    # search_params::    Full-text search string forwarded to Solr. Defaults to an empty string.
    # selected_facets::  Hash of active facet filters (field name → value). Special facets
    #                    (see +Facets.special+) are handled separately from normal ones.
    # page::             Current page number for pagination. Defaults to +1+.
    # sort_by::          Sort key string (+nil+ or <tt>'default'</tt> uses the model-specific
    #                    default ordering; other accepted values: <tt>'early'</tt>,
    #                    <tt>'late'</tt>, <tt>'rel'</tt>, <tt>'mod'</tt>, <tt>'new'</tt>,
    #                    <tt>'finished'</tt>, or any field name accepted by Solr).
    # per_page::         Number of results per page. Defaults to +30+.
    # space::            The +Space+ to scope results to, or +nil+ / the default space to
    #                    search across all spaces the user can access.
    #
    # Returns:: A +Sunspot::Search::StandardSearch+ result object whose +#results+ contain
    #           the matching, access-filtered, paginated model instances.
    def search_and_filter(user, search_params = '', selected_facets = {}, page: 1, sort_by: nil, per_page: 30, space: nil)
      includes = Searchable::EAGER_LOADABLE.select { |a| reflections.key?(a.to_s) }

      has_space = attribute_method?(:space_id)
      has_public = attribute_method?(:public)
      has_collaborators = attribute_method?(:collaborators)

      accessible_space_ids = nil
      inaccessible_space_ids = nil

      if has_space && (space.nil? || space.default?)
        inaccessible_space_ids = Space.where(is_private: true).pluck(:id)
      end

      search(include: includes) do
        if has_space
          if space && !space.default?
            with(:space_id, space.id)
          else
            if inaccessible_space_ids.present?
              without(:space_id, inaccessible_space_ids)
            end
          end
        end

        fulltext search_params
        active_facets = {}
        normal_facets = selected_facets.except(*Facets.special)

        any do
          normal_facets.each do |facet_title, facet_value|
            any do
              active_facets[facet_title] ||= []
              val = Facets.process(facet_title, facet_value)
              active_facets[facet_title] << with(facet_title, val)
            end
          end
        end

        if sort_by && sort_by != 'default'
          case sort_by
          when 'early'   then order_by(:start, :asc)
          when 'late'    then order_by(:start, :desc)
          when 'rel'     then nil
          when 'mod'     then order_by(:updated_at, :desc)
          when 'new'     then order_by(:created_at, :desc)
          when 'finished' then order_by(:finished_at, :desc)
          else                order_by(:sort_title, sort_by.to_sym)
          end
        else
          case name
          when 'Event'           then order_by(:start, :asc)
          when 'ContentProvider' then order_by(:count, :desc)
          when 'Material'        then order_by(:created_at, :desc)
          else                        order_by(:sort_title, :asc)
          end
        end

        paginate page: page, per_page: per_page unless page.nil?;

        Facets.special.each do |facet_title|
          if Facets.applicable?(facet_title, self)
            facet_value = Facets.process(facet_title, selected_facets[facet_title])
            Facets.send(facet_title.to_sym, self, facet_value, user)
          end
        end

        if name == 'Trainer' || name == 'Profile'
          any_of { with(:public, true) }
        elsif has_public && !user&.is_admin?
          any_of do
            with(:public, true)
            with(:user_id, user.id) if user
            with(:collaborator_ids, user.id) if user && has_collaborators
          end
        end

        facet_fields.each do |ff|
          facet ff, exclude: active_facets[ff]
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
