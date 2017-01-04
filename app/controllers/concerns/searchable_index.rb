module SearchableIndex
  extend ActiveSupport::Concern

  included do
    attr_reader :facet_fields, :search_params, :facet_params, :page, :sort_by, :index_resources
    before_action :set_params, only: :index
    before_action :fetch_resources, only: :index

    helper 'search'
  end

  def fetch_resources
    if SOLR_ENABLED
      @search_results = solr_search(@model, @search_params, @facet_params,
                                    page: @page, per_page: @per_page, sort_by: @sort_by)
      @index_resources = @search_results.results
      instance_variable_set("@#{controller_name}_results", @search_results) # e.g. @nodes_results
    else
      @index_resources = policy_scope(@model).paginate(page: @page)
    end

    instance_variable_set("@#{controller_name}", @index_resources) # e.g. @nodes
  end

  def set_params
    @model = controller_name.classify.constantize
    @facet_fields = @model.send(:facet_fields)
    params.permit(:q, :page, :sort, @facet_fields, @facet_fields.map { |f| "#{f}_all" })
    @search_params = params[:q] || ''
    @facet_params = {}
    @sort_by = params[:sort].blank? ? 'default' : params[:sort]
    @facet_fields.each { |facet_title| @facet_params[facet_title] = params[facet_title] unless params[facet_title].blank? }
    @facet_params['include_expired'] = true if params[:include_expired] # TODO: Move this
    if params[:days_since_scrape] # TODO: Move this
      @facet_params['days_since_scrape'] = params[:days_since_scrape]
    end
    @page = params[:page].blank? ? 1 : params[:page]
    @per_page = params[:per_page].blank? ? 30 : params[:per_page]
  end

  private

  def solr_search(model, search_params = '', selected_facets = [], page: 1, sort_by: nil, per_page: 30)
    model.search do
      fulltext search_params
      # Set the search parameter
      # Disjunction clause
      active_facets = {}

      any do
        # Set all facets
        selected_facets.each do |facet_title, facet_value|
          next if %w(include_expired days_since_scrape).include?(facet_title)
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
      elsif model == Event
        order_by(:start, :asc)
      elsif [Material, Workflow, Package].include? model
        order_by(:sort_title, :asc)
      elsif [Node].include? model
        order_by(:sort_title, :asc)
      elsif [ContentProvider].include? model
        order_by(:count, :desc)
      end

      paginate page: page, per_page: per_page if !page.nil? && (page != '1')

      # Go through the selected facets and apply them and their facet_values
      if model == Event
        unless selected_facets.keys.include?('include_expired') && (selected_facets['include_expired'] == true)
          with('end').greater_than(Time.zone.now)
        end
      end

      if selected_facets.keys.include?('days_since_scrape')
        with(:last_scraped).less_than(selected_facets['days_since_scrape'].to_i.days.ago)
      end

      if model.attribute_method?(:public) && !(current_user && current_user.is_admin?) # Find a better way of checking this
        any_of do
          with(:public, true)
          with(:user_id, current_user.id) if current_user
          if model.attribute_method?(:collaborators)
            with(:collaborator_ids, current_user.id) if current_user
          end
        end
      end

      facet_fields.each do |ff|
        facet ff, exclude: active_facets[ff]
      end
    end
  end
end
