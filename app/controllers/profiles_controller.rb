class ProfilesController < ApplicationController

  # Controller for showing public profiles.
  prepend_before_action :set_user_profile

  # Skip the parent's before_action
  skip_before_action :authenticate_user!
  # and define it on all methods
  before_action :authenticate_user!

  include TeSS::BreadCrumbs

  def show
  end

  def edit
  end

  def update
    respond_to do |format|
      if @profile.update(profile_params)
        format.html { redirect_to @profile, notice: 'Profile was successfully updated.' }
        format.json { render :show, status: :ok, location: @profile }
      else
        format.html { render :edit }
        format.json { render json: @profile.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_user_profile
    begin
      @user = User.friendly.find(params[:id])
      @profile = @user.profile
    rescue
      redirect_to root_path, notice: "Sorry, that profile couldn't be found."
    end
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def profile_params
    params.require(:profile).permit!
  end

  protected

  # Override
  def check_authorised
    if (current_user.nil?)
      return # user has not been logged in yet!
    else
      if current_user.id == @user.id or current_user.is_admin?
        return
      end
    end
    flash[:error] = "Sorry, you're not allowed to view that page."
    redirect_to root_path
  end

end