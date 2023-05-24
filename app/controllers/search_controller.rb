# frozen_string_literal: true

# The controller for actions related to searchable models
class SearchController < ApplicationController
  PAGE_SIZE = 30

  before_action :set_breadcrumbs

  # GET /searches
  # GET /searches.json
  def index
    @results = {}

    if TeSS::Config.solr_enabled
      search_models.each do |model_name|
        model = model_name.constantize
        @results[model_name.underscore.pluralize.to_sym] = Sunspot.search(model) do
          fulltext search_params

          with('end').greater_than(Time.zone.now) if model_name == 'Event'

          # Hide failing records
          without(:failing, true) if model.method_defined?(:link_monitor) && !(current_user && current_user.is_admin?)

          if model_name == 'User' || model.attribute_method?(:user_requires_approval?)
            # TODO: Fix this duplication!
            # Hide shadowbanned users and their content from other shadowbanned users and administrators
            without(:shadowbanned, true) unless current_user && (current_user.shadowbanned? || current_user.is_admin?)

            # Hide unverified users and their content from other shadowbanned users and administrators
            without(:unverified, true) unless current_user && (current_user.is_curator? || current_user.is_admin?)
          end

          paginate page: 1, per_page: PAGE_SIZE
        end
      end
    end

    @results.reject! { |_, result| result.total < 1 }
  end

  private

  def search_params
    params[:q]
  end

  def search_models
    return @_models if @_models

    @_models = ['User']
    @_models << 'Event' if TeSS::Config.feature['events']
    @_models << 'Material' if TeSS::Config.feature['materials']
    @_models << 'Collection' if TeSS::Config.feature['collections']
    @_models << 'ContentProvider' if TeSS::Config.feature['content_providers']
    @_models << 'Trainer' if TeSS::Config.feature['trainers']
    @_models
  end
end
