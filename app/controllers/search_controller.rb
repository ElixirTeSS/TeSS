class SearchController < ApplicationController
  include Tess::BreadCrumbs

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

  private

  def search_params
    params[:q]
  end
end
