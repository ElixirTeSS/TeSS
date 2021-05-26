# The controller for actions related to Resolution actions
class ResolutionController < ApplicationController

  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def resolve
    model = resolve_model

    if model
      respond_to do |format|
        format.any { redirect_to send("#{model.name.underscore}_path", params[:id], format: params[:format]) }
      end
    else
      handle_error(400, "Unrecognized type: '#{params[:type]}' (valid types are: e, m, p, w)")
    end
  end

  private

  def resolve_model
    case params[:type].downcase
    when 'e'
      Event
    when 'm'
      Material
    when 'p'
      ContentProvider
    when 'w'
      Workflow
    end
  end
end
