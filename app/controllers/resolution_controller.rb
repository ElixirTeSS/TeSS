# frozen_string_literal: true

# The controller for actions related to Resolution actions
class ResolutionController < ApplicationController
  before_action :parse_identifier
  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def resolve
    model = resolve_model

    if model
      respond_to do |format|
        format.any { redirect_to send("#{model.name.underscore}_path", @identifier[:id], format: params[:format]) }
      end
    else
      handle_error(400, "Unrecognized type: '#{@identifier[:type]}' (valid types are: e, m, p, w)")
    end
  end

  private

  def resolve_model
    case @identifier[:type].downcase
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

  def parse_identifier
    matches = params[:id].match(/(?<prefix>.+:)?(?<type>[a-zA-Z])(?<id>\d+)/)
    raise ActionController: RoutingError unless matches

    @identifier = matches
  end
end
