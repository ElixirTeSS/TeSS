# The controller for actions related to the Profiles model
class TrainersController < ApplicationController
  before_action :set_trainer, only: [:show]
  before_action :set_breadcrumbs

  include SearchableIndex
  include ActionView::Helpers::TextHelper

  # GET /trainers
  # GET /trainers?q=queryparam
  # GET /trainers.json
  # GET /trainers.json?q=queryparam

  def index
    respond_to do |format|
      format.json
      format.json_api { render({ json: @trainers }.merge(api_collection_properties)) }
      format.html
    end
  end

  # GET /trainers/1
  # GET /trainers/1.json

  def show
    respond_to do |format|
      format.json
      format.json_api { render json: @trainer }
      format.html
    end
  end

  private

  def set_trainer
    @trainer = Trainer.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def trainer_params
    params.require(:trainer).permit(:id, :firstname, :surname, :website,
                                    :orcid, :email, :public, :description,
                                    :location, :experience, { :language => [] }, { :expertise_academic => [] },
                                    { :expertise_technical => [] }, { :interest => [] }, { :activity => [] },
                                    { :fields => [] }, { :social_media => [] })
  end

end