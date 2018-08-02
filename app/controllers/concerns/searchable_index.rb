module SearchableIndex
  extend ActiveSupport::Concern

  included do
    attr_reader :facet_fields, :search_params, :facet_params, :page, :sort_by, :index_resources
    before_action :set_params, only: [:index, :count]
    before_action :fetch_resources, only: [:index, :count]

    helper 'search'
  end

  def count
    respond_to do |format|
      format.json { render 'common/count' }
    end
  end

  def fetch_resources
    if TeSS::Config.solr_enabled
      page = page_param.blank? ? 1 : page_param.to_i
      per_page = per_page_param.blank? ? 30 : per_page_param.to_i

      @search_results = @model.search_and_filter(current_user, @search_params, @facet_params,
                                    page: page, per_page: per_page, sort_by: @sort_by)
      @index_resources = @search_results.results
      instance_variable_set("@#{controller_name}_results", @search_results) # e.g. @nodes_results
    else
      @index_resources = policy_scope(@model).paginate(page: @page)
    end

    instance_variable_set("@#{controller_name}", @index_resources) # e.g. @nodes
  end

  def set_params
    @model = controller_name.classify.constantize
    @facet_params = params.permit(*@model.facet_keys).to_h
    @search_params = params[:q] || ''
    @sort_by = params[:sort].blank? ? 'default' : params[:sort]
  end

  def api_collection_properties
    if TeSS::Config.solr_enabled
      # Transform facets so value is always an array
      facets = @facet_params.to_h
      facets.each { |key, value| facets[key] = Array(value) }

      available_facets = Hash[@search_results.facets.map do |f|
        [
            f.field_name,
            f.rows.map { |r| { value: r.value, count: r.count } }
        ]
      end]
      total = @search_results.total
    else
      facets = {}
      available_facets = {}
      total = @index_resources.count
    end

    {
        links: {
            # This gets overridden (by something in ActiveModelSerializers)when the collection has multiple pages
            self: polymorphic_path(@model, search_and_facet_params)
        },
        meta: {
            facets: facets,
            available_facets: available_facets,
            query: @search_params,
            results_count: total
        }
    }
  end

  def page_param
    params[:page] || params[:page_number]
  end

  def per_page_param
    params[:per_page] || params[:page_size]
  end

  def search_and_facet_params
    params.permit(*@model.search_and_facet_keys)
  end
end
