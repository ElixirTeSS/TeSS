class UsersController < ApplicationController

  prepend_before_action :set_user, only: [:show, :edit, :update, :destroy, :change_token]
  prepend_before_action :init_user, only: [:new, :create]
  before_action :set_breadcrumbs

  #
  # # Skip the parent's before_action, which is defined only on some methods
  # skip_before_action :authenticate_user!
  # # and define it on all methods
  # before_action :authenticate_user!

  # GET /users
  # GET /users.json
  def index
    @users = User.all
    respond_to do |format|
      format.html
      format.json
      format.json_api { render(json: @users, links: { self: users_path }) }
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

  # GET /users/new
  def new
    authorize User
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
  #THIS IS FOR UPDATING PROFILES
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
      format.html { redirect_to users_path, notice: 'User was successfully destroyed.' }  # Devise is also doing redirection here
      format.json { head :no_content }
    end
  end

  def change_token
    authorize @user
    if @user.authentication_token.nil?
      handle_error(:unprocessable_entity, "Authentication token cannot be set to nil - action not allowed (status code: 422 Unprocessable Entity).") and return
    end
    @user.authentication_token = Devise.friendly_token
    if @user.save
      flash[:notice] = "Authentication token successfully regenerated."
      redirect_to @user
    else
      handle_error(:unprocessable_entity, "Failed to regenerate Authentication token (status code: 422 Unprocessable Entity).")
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
    allowed_parameters = [:email, :username, :password, { profile_attributes: [:firstname, :surname, :email, :website] }]
    allowed_parameters << :role_id if policy(@user).change_role?
    params.require(:user).permit(allowed_parameters)
  end

end
