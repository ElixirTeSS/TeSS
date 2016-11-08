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
      @search_results = solr_search(@model, @search_params, @facet_params, @page, @sort_by)
      @index_resources = @search_results.results
      instance_variable_set("@#{controller_name}_results", @search_results) #e.g. @nodes_results
    else
      @index_resources = policy_scope(@model).paginate(page: params[:page])
    end

    instance_variable_set("@#{controller_name}", @index_resources) # e.g. @nodes
  end

  def set_params
    @model = controller_name.classify.constantize
    @facet_fields = @model.send(:facet_fields)
    params.permit(:q, :page, :sort, @facet_fields, @facet_fields.map{|f| "#{f}_all"})
    @search_params = params[:q] || ''
    @facet_params = {}
    @sort_by = params[:sort]
    @facet_fields.each {|facet_title| @facet_params[facet_title] = params[facet_title] if !params[facet_title].nil? }
    if params[:include_expired] # TODO: Move this
      @facet_params['include_expired'] = true
    end
    if params[:days_since_scrape] # TODO: Move this
      @facet_params['days_since_scrape'] = params[:days_since_scrape]
    end
    @page = params[:page] || 1
  end

  private

  def solr_search(model, search_params='', selected_facets=[], page=1, sort_by=nil)
    model.search do

      fulltext search_params
      #Set the search parameter
      #Disjunction clause
      facets = []

      any do
        #Set all facets
        selected_facets.each do |facet_title, facet_value|
          if !['include_expired', 'days_since_scrape'].include?(facet_title)
            any do #Conjunction clause
              #Convert 'true' or 'false' to boolean true or false
              if facet_title == 'online'
                if facet_value and facet_value == 'true'
                  facet_value = true
                else
                  facet_value = false
                end
              end
              # Add to array that get executed lower down
              facets << with(facet_title, facet_value)
            end
          end
        end
      end

      if sort_by
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

      if !page.nil? and page != '1'
        paginate :page => page
      end

      #Go through the selected facets and apply them and their facet_values
      if model == Event
        facet 'start'
        unless selected_facets.keys.include?('include_expired') and selected_facets['include_expired'] == true
          with('end').greater_than(Time.zone.now)
        end
      end

      if selected_facets.keys.include?('days_since_scrape')
        with(:last_scraped).less_than(selected_facets['days_since_scrape'].to_i.days.ago)
      end

      if model.method_defined?(:public?) # Find a better way of checking this
        any_of do
          with(:public, true)
          with(:user_id, current_user.id) if current_user
        end
      end

      facet_fields.each do |ff|
        facet ff, exclude: facets
      end
    end
  end
end
