class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :check_auth, only: [:show, :edit, :update, :destroy]
  before_action :check_admin, only: [:show, :edit, :new]
  before_action :closed_route, only: [:new, :update, :edit]

  before_filter :authenticate_user!

  # GET /users
  # GET /users.json
  def index
    @users = User.all
  end

  # GET /users/1
  # GET /users/1.json
  def show
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    @user = User.new(user_params)
    logger.info "PARAMS: #{user_params}"
    logger.info "USER: #{@user.inspect}"

    respond_to do |format|
      if @user.save
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
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def change_token
    @user = current_user
    if @user.authentication_token.nil?
      flash[:alert] = "Action not allowed."
      redirect_to root_path and return
    end
    @user.authentication_token = Devise.friendly_token
    if @user.save
      flash[:notice] = "API key changed."
      redirect_to "/users/#{@user.profile.id}"
    else
      flash[:alert] = "Failed to change api_key."
      redirect_to root_path
    end
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.friendly.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
      params.require(:user).permit!
    end

    def check_auth
      if current_user.id == @user.id or current_user.is_admin?
        return
      end
      redirect_to root_path, notice: "Sorry, you're not allowed to view that page."
    end

    # This is here because users shouldn't be accessing the user edit page directly -
    # the profile is for extra information about them and their password should be changed
    # by the usual devise mechansims.
    def check_admin
      if current_user
        if current_user.is_admin?
          return
        end
      end
      redirect_to root_path, notice: "Sorry, you're not allowed to view that page."
    end

    def closed_route
      if !((request.post? or request.put? or request.patch?) and request.format.json?)
        redirect_to root_path, notice: 'Sorry, that page is not available.'
      end
    end
end
