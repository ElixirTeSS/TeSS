# The controller for actions related to the Ban model
class BansController < ApplicationController

  before_action :get_user
  before_action :auth
  before_action :set_breadcrumbs

  def create
    @ban = @user.create_ban(ban_params.merge(banner: current_user))

    flash[:notice] = "User #{'shadow' if @ban.shadow?}banned"

    redirect_to @user
  end

  def destroy
    @user.ban.destroy

    flash[:notice] = 'Ban lifted'

    redirect_to @user
  end

  def new
    @ban = @user.build_ban(shadow: true)
  end

  private

  def get_user
    @user = User.friendly.find(params[:user_id])
  end

  def auth
    authorize @user, :ban?
  end

  def ban_params
    params.require(:ban).permit(:reason, :shadow)
  end

  def set_breadcrumbs
    add_base_breadcrumbs('users')
    @breadcrumbs += [{ name: @user.name, url: user_path(@user) }, { name: 'Ban' }]
  end
end
