# The concern for searchable index
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
    # If the model uses an alias, use that for the search instead
    if defined? controller_name.classify.constantize.alias
      @model = controller_name.classify.constantize.alias.constantize
    else
      @model = controller_name.classify.constantize
    end

    @facet_params = params.permit(*@model.facet_keys_with_multiple).to_h
    # Add any preexisting filters from the model
    if defined? controller_name.classify.constantize.filter
      @facet_params = @facet_params.merge(controller_name.classify.constantize.filter)
    end
    @search_params = params[:q] || ''
    @sort_by = params[:sort].blank? ? 'default' : params[:sort]
  end

  def api_collection_properties
    links = {
        self: polymorphic_path(@model, search_and_facet_params)
    }
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

      res = @index_resources
      p = search_and_facet_params
      links[:first] = polymorphic_path(@model, p.merge(page_number: 1)) if res.current_page != 1
      links[:prev] = polymorphic_path(@model, p.merge(page_number: res.previous_page)) if res.previous_page
      links[:next] = polymorphic_path(@model, p.merge(page_number: res.next_page)) if res.next_page
      links[:last] = polymorphic_path(@model, p.merge(page_number: res.total_pages)) if res.current_page != res.total_pages
    else
      facets = {}
      available_facets = {}
      total = @index_resources.count
    end


    {
        links: links,
        meta: {
            facets: facets,
            available_facets: available_facets,
            query: @search_params,
            results_count: total
        }
    }
  end

  def page_param
    pagination_params[:page] || pagination_params[:page_number]
  end

  def per_page_param
    pagination_params[:per_page] || pagination_params[:page_size]
  end

  def pagination_params
    params.permit(:page, :page_number, :per_page, :page_size)
  end

  def search_and_facet_params
    params.permit(*(@model.search_and_facet_keys | [:page_size, :page_number, :page, :per_page]))
  end
end
