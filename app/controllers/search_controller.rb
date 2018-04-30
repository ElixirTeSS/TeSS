class SearchController < ApplicationController

  before_action :set_breadcrumbs

  SEARCH_MODELS = %w(Material User Event Package ContentProvider Workflow).freeze

  # GET /searches
  # GET /searches.json
  def index
    @results = {}

    if TeSS::Config.solr_enabled
      SEARCH_MODELS.each do |model_name|
        model = model_name.constantize
        @results[model_name.underscore.pluralize.to_sym] = Sunspot.search(model) do
          fulltext search_params

          with('end').greater_than(Time.zone.now) if model_name == 'Event'

          # Hide failing records
          if model.method_defined?(:link_monitor)
            unless current_user && current_user.is_admin?
              without(:failing, true)
            end
          end

          if model.attribute_method?(:user)
            # TODO: Fix this duplication!
            # Hide shadowbanned users' events, except from other shadowbanned users and administrators
            unless current_user && (current_user.shadowbanned? || current_user.is_admin?)
              without(:user_id, User.shadowbanned.pluck(:id))
            end

            # Hide unverified users' things, except from curators and admins
            unless current_user && (current_user.is_curator? || current_user.is_admin?)
              unverified_user_ids = User.with_role('unverified_user').pluck(:id)
              unverified_user_ids -= [current_user.id] if current_user # Let them see their own things
              without(:user_id, unverified_user_ids)
            end
          end
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
