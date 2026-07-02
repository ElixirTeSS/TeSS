# The concern for searchable index.
#
# Mixed into resource controllers to provide a shared +index+/+count+
# implementation that supports Solr-backed search and faceting when
# <tt>TeSS::Config.solr_enabled</tt> is true, and falls back to a plain
# Pundit-scoped, paginated listing otherwise.
#
# Including controllers are expected to expose <tt>@#{controller_name}</tt>
# (e.g. <tt>@nodes</tt>) to their views; this concern sets that instance
# variable automatically in #fetch_resources.
module SearchableIndex
  # Default number of records per page when none is requested.
  DEFAULT_PAGE_SIZE = 10

  # Allowed values for the +per_page+/+page_size+ parameter.
  PER_PAGE_OPTIONS = [10, 20, 50, 100]

  extend ActiveSupport::Concern

  included do
    attr_reader :facet_fields, :search_params, :facet_params, :page, :sort_by, :index_resources
    before_action :set_params, only: [:index, :count]
    before_action :fetch_resources, only: [:index, :count]

    helper 'search'
  end

  # GET (JSON) /<resources>/count
  #
  # Renders the total result count for the current search/filter
  # parameters as JSON, using the shared <tt>common/count</tt> partial.
  def count
    respond_to do |format|
      format.json { render 'common/count' }
    end
  end

  # Loads the resources for the +index+/+count+ actions into
  # <tt>@index_resources</tt> and <tt>@#{controller_name}</tt>.
  #
  # When Solr is enabled, delegates to <tt>@model.search_and_filter</tt>,
  # filters the results through Pundit (#policy(record).shown?), and wraps
  # the filtered set in a WillPaginate::Collection with a corrected total.
  # Otherwise falls back to a plain <tt>policy_scope(@model).paginate</tt>.
  def fetch_resources
    if TeSS::Config.solr_enabled
      page = page_param.blank? ? 1 : page_param.to_i
      per_page = per_page_param.blank? ? DEFAULT_PAGE_SIZE : per_page_param.to_i

      @search_results = @model.search_and_filter(current_user, @search_params, @facet_params,
                                    page: page, per_page: per_page, sort_by: @sort_by)

      filtered = @search_results.results.select { |record| policy(record).shown? }

      # Override total on the Solr result object so the view gets the right count
      @search_results.instance_variable_set(:@total, filtered.length)
      def @search_results.total; @total; end

      @index_resources = WillPaginate::Collection.create(page, per_page, filtered.length) do |pager|
        pager.replace(filtered)
      end

      instance_variable_set("@#{controller_name}_results", @search_results) # e.g. @nodes_results
    else
      @index_resources = policy_scope(@model).paginate(page: @page)
    end

    instance_variable_set("@#{controller_name}", @index_resources) # e.g. @nodes
  end

  # before_action that resolves the target model class from the controller
  # name, and extracts the search query, facet, and sort parameters from
  # the request into +@model+, +@facet_params+, +@search_params+ and
  # +@sort_by+.
  def set_params
    # If the model uses an alias, use that for the search instead
    @model = controller_name.classify.constantize

    @facet_params = params.permit(*@model.facet_keys_with_multiple).to_h
    @search_params = params[:q] || ''
    @sort_by = params[:sort].blank? ? 'default' : params[:sort]
  end

  # Builds the JSON:API-style +links+ and +meta+ block (pagination links,
  # facets, available facets, query and result count) describing the
  # current search/index collection.
  #
  # Returns:: a Hash with +:links+ and +:meta+ keys, suitable for merging
  #           into a JSON:API collection response.
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
          :'available-facets' => available_facets,
          query: @search_params,
          :'results-count' => total
        }
    }
  end

  # Returns:: the requested page number from +params+ (+:page+ or
  #           +:page_number+), as a String, or +nil+ if not present.
  def page_param
    pagination_params[:page] || pagination_params[:page_number]
  end

  # Returns:: the requested page size from +params+ (+:per_page+ or
  #           +:page_size+), as a String, or +nil+ if not present.
  def per_page_param
    pagination_params[:per_page] || pagination_params[:page_size]
  end

  # Returns:: the permitted pagination parameters (+:page+, +:page_number+,
  #           +:per_page+, +:page_size+).
  def pagination_params
    params.permit(:page, :page_number, :per_page, :page_size)
  end

  # Returns:: the permitted search and facet parameters for +@model+,
  #           merged with the pagination parameter keys, suitable for
  #           building pagination/self links.
  def search_and_facet_params
    params.permit(*(@model.search_and_facet_keys | [:page_size, :page_number, :page, :per_page]))
  end
end