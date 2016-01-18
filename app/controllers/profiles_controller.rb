class ProfilesController < ApplicationController
  # Controller for showing public profiles.
  before_action :set_user_profile
  before_action :check_auth, only: [:edit]

  before_filter :authenticate_user!


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

  def check_auth
    if current_user.id == @user.id or current_user.is_admin?
      return
    end
    redirect_to root_path, notice: "Sorry, you're not allowed to view that page."
  end

end