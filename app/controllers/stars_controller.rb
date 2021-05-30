# The controller for actions related to the Stars model
class StarsController < ApplicationController

  before_action :authenticate_user!

  def index
    @stars = current_user.stars.order('created_at DESC')
  end

  def create
    @star = current_user.stars.where(star_params).first_or_initialize
    @star.assign_attributes(star_params)

    if @star.save
      respond_to do |format|
        format.json { render json: @star.to_json, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: @star.errors.to_json, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @star = current_user.stars.where(star_params).first

    if @star.destroy
      respond_to do |format|
        format.json { render json: {}, status: :ok }
      end
    else
      respond_to do |format|
        format.json { render json: {}, status: :unprocessable_entity }
      end
    end
  end
  
  private

  def star_params
    params.require(:star).permit(:resource_type, :resource_id)
  end

end
