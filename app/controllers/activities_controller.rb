class ActivitiesController < ApplicationController

  before_action :set_resource, only: [:show]
  before_action :set_breadcrumbs

  @@models = %w( content_provider material package event )

  def index
    @activities = PublicActivity::Activity.order('created_at desc').paginate(page: params[:page], per_page: 50)
  end

  def show
    render 'activities/show', :locals => {:resource => @resource}
  end

  private

  def set_resource
    params.permit(@@models)

    @@models.each do |model|
      parameter_name = model+'_id'
      if params.include?(parameter_name)
        resource_model = model.camelcase.constantize
        @resource = resource_model.friendly.find(params[parameter_name])
      end
    end
  end
end
