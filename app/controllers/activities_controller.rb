# The controller for actions related to the Activities model
class ActivitiesController < ApplicationController

  before_action :set_resource, only: [:index]
  before_action :set_breadcrumbs, only: [:index]

  MODELS = %w[content_provider material collection event node workflow source learning_path learning_path_topic space].freeze

  def show
    raise ActionController::RoutingError.new("") unless current_user&.is_admin?
    @activity = PublicActivity::Activity.find(params[:id])
  end

  def index
    if request.xhr?
      @activities = @resource.activities.order('created_at desc')
      respond_to do |format|
        format.html { render partial: 'activities/activity_log', locals: { activities: @activities } }
      end
    else
      @activities = @resource.activities.order('created_at desc').paginate(page: params[:page], per_page: 50)
      respond_to do |format|
        format.html
      end
    end
  end

  private

  def set_resource
    MODELS.each do |model|
      parameter_name = model+'_id'
      if params.include?(parameter_name)
        resource_model = model.camelcase.constantize
        @resource = (resource_model.respond_to?(:friendly) ? resource_model.friendly : resource_model).find(params[parameter_name])
      end
    end
  end
end
