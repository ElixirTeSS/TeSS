class BansController < ApplicationController

  before_filter :get_user
  before_action :set_breadcrumbs

  def create
    authorize @user, :ban?

    @ban = @user.create_ban(ban_params.merge(banner: current_user))

    flash[:notice] = "User #{'shadow' if @ban.shadow?}banned"

    redirect_to @user
  end

  def destroy
    authorize @user, :ban?

    @user.ban.destroy

    flash[:notice] = 'Ban lifted.'

    redirect_to @user
  end

  def new
    @ban = @user.build_ban(shadow: true)
  end

  private

  def get_user
    @user = User.find_by_slug(params[:user_id])
  end

  def auth
  end

  def ban_params
    params.require(:ban).permit(:reason, :shadow)
  end

  def set_breadcrumbs
    add_base_breadcrumbs('users')
    @breadcrumbs += [{ name: @user.name, url: user_path(@user) }, { name: 'Ban' }]
  end
end
