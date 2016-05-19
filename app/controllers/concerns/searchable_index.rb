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
      @index_resources = solr_search(@model, @search_params, @facet_params, @page, @sort_by)
    else
      @index_resources = @model.all
    end
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
    @page = params[:page] || 1
  end
end
