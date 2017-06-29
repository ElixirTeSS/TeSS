class SearchController < ApplicationController

  before_action :set_breadcrumbs

  SEARCH_MODELS = %w(Material User Event Package ContentProvider Workflow).freeze

  # GET /searches
  # GET /searches.json
  def index
    @results = {}

    if TeSS::Config.solr_enabled
      SEARCH_MODELS.each do |model_name|
        @results[model_name.underscore.pluralize.to_sym] = Sunspot.search(model_name.constantize) do
          fulltext search_params
          with('end').greater_than(Time.zone.now) if model_name == 'Event'
        end
      end
    end

    @results.reject! { |_, result| result.total < 1 }
  end

  def count_events
    @output = {}

    if TeSS::Config.solr_enabled
      results = Sunspot.search('Event'.constantize) do
        fulltext search_params
        with('end').greater_than(Time.zone.now)
      end
    end

    @output['count'] = results.total
    @output['url'] = "http://#{request.host_with_port}"

    if search_params
      @output['url'] += "?q=#{search_params}"
    end

    render json: @output
  end

  private

  def search_params
    params[:q]
  end
end
