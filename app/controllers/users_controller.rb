# frozen_string_literal: true

# The controller for actions related to the Users model
class UsersController < ApplicationController
  before_action -> { ensure_feature_enabled('invitation') }, only: [:invitees]
  prepend_before_action :set_user, only: %i[show edit update destroy change_token]
  prepend_before_action :init_user, only: [:create]
  before_action :set_breadcrumbs
  before_action :check_profile_id, only: [:update]

  include ActionView::Helpers::TextHelper

  # GET /users
  # GET /users.json
  def index
    @users = User.visible
    @users = @users.with_query(params[:q].chomp('*')) if params[:q].present?
    @users = @users.paginate(page: params[:page], per_page: 50)

    respond_to do |format|
      format.html
      format.json
      format.json_api { render(json: @users, links: { self: users_path }) }
    end
  end

  # GET/invitees
  def invitees
    if current_user.is_admin? || current_user.is_curator?
      @users = User.invited
      respond_to do |format|
        format.html
      end
    else
      redirect_to users_path
    end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    respond_to do |format|
      format.html
      format.json
      format.json_api { render json: @user }
    end
  end

  # GET /users/1/edit
  def edit
    authorize @user
  end

  # POST /users
  # POST /users.json
  def create
    authorize User
    @user.assign_attributes(user_params)
    logger.info "PARAMS: #{user_params}"
    logger.info "USER: #{@user.inspect}"

    respond_to do |format|
      if @user.save
        @user.create_activity :create, owner: current_user
        format.html { redirect_to @user, notice: 'User was successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  # THIS IS FOR UPDATING PROFILES
  def update
    authorize @user
    respond_to do |format|
      if @user.update(user_params)
        @user.create_activity :update, owner: current_user
        format.html { redirect_to @user, notice: 'Profile was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
        format.js { head :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
        format.js { head :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    authorize @user
    @user.create_activity :destroy, owner: current_user
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_path, notice: 'User was successfully destroyed.' } # Devise is also doing redirection here
      format.json { head :no_content }
    end
  end

  def change_token
    authorize @user
    handle_error(:unprocessable_entity, 'Authentication token cannot be set to nil - action not allowed (status code: 422 Unprocessable Entity).') and return if @user.authentication_token.nil?

    @user.authentication_token = Devise.friendly_token
    if @user.save
      flash[:notice] = 'Authentication token successfully regenerated.'
      redirect_to @user
    else
      handle_error(:unprocessable_entity, 'Failed to regenerate Authentication token (status code: 422 Unprocessable Entity).')
    end
  end

  private

  def set_user
    @user = User.friendly.find(params[:id])
  end

  # Need to do this before `user_params` is called, to ensure policy(@user).change_role? works
  def init_user
    @user = User.new
  end

  def user_params
    allowed_parameters = [:email, :username, :password, :image, :image_url, {
      profile_attributes: [:id, :firstname, :surname, :email, :website, :public,
                           :description, :location, :orcid, :experience,
                           { expertise_academic: [] }, { expertise_technical: [] },
                           { interest: [] }, { activity: [] }, { language: [] },
                           { fields: [] }, { social_media: [] }]
    }]
    allowed_parameters << :role_id if policy(@user).change_role?
    allowed_parameters << :check_broken_scrapers if @user.is_admin?
    params.require(:user).permit(allowed_parameters)
  end

  # Prevent assigning other profiles
  def check_profile_id
    profile_id = @user.profile.id
    incoming_id = user_params.dig(:profile_attributes, :id)
    if profile_id && incoming_id && profile_id.to_i != incoming_id.to_i
      handle_error(:forbidden, 'Invalid profile ID.')
    end
  end
end
