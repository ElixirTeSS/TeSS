module SearchableIndex
  extend ActiveSupport::Concern

  included do
    attr_reader :facet_fields, :search_params, :facet_params, :page, :sort_by, :index_resources
    before_action :set_params, only: :index
    before_action :fetch_resources, only: :index

    helper 'search'
  end

  def fetch_resources
    if TeSS::Config.solr_enabled
      page = params[:page].blank? ? 1 : params[:page]
      per_page = params[:per_page].blank? ? 30 : params[:per_page]

      if params[:days_since_scrape] # TODO: Move this
        @facet_params['days_since_scrape'] = params[:days_since_scrape]
      end

      max_age = nil
      if params[:max_age].present?
        @facet_params['max_age'] = params[:max_age]
        max_age = Subscription::FREQUENCY.detect { |f| f[:title] == params[:max_age] }.try(:[], :period)
      end
      @search_results = @model.search_and_filter(current_user, @search_params, @facet_params,
                                    page: page, per_page: per_page, sort_by: @sort_by, max_age: max_age)
      @index_resources = @search_results.results
      instance_variable_set("@#{controller_name}_results", @search_results) # e.g. @nodes_results
    else
      @index_resources = policy_scope(@model).paginate(page: @page)
    end

    instance_variable_set("@#{controller_name}", @index_resources) # e.g. @nodes
  end

  def set_params
    @model = controller_name.classify.constantize
    facet_fields = @model.send(:facet_fields)
    params.permit(:q, :page, :sort, :elixir, facet_fields, facet_fields.map { |f| "#{f}_all" })
    @search_params = params[:q] || ''
    @facet_params = {}
    @sort_by = params[:sort].blank? ? 'default' : params[:sort]
    facet_fields.each { |facet_title| @facet_params[facet_title] = params[facet_title] unless params[facet_title].blank? }
    @facet_params['include_expired'] = true if params[:include_expired] # TODO: Move this
    if params[:elixir] == 'true'
      @facet_params['elixir'] = true
    elsif params[:elixir] == 'false'
      @facet_params['elixir'] = false
    end
  end

end
