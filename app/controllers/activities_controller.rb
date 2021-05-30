# The controller for actions related to the Activities model
class ActivitiesController < ApplicationController

  before_action :set_resource, only: [:index]
  before_action :set_breadcrumbs

  MODELS = %w[content_provider material package event node workflow].freeze

  def index
    if request.xhr?
      @activities = PublicActivity::Activity.order('created_at desc')
      respond_to do |format|
        format.html { render partial: 'activities/activity_log', locals: { resource: @resource } }
      end
    else
      @activities = PublicActivity::Activity.order('created_at desc').paginate(page: params[:page], per_page: 50)
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
        @resource = resource_model.friendly.find(params[parameter_name])
      end
    end
  end
end
