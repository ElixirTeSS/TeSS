class IdentitiesController < ApplicationController
  prepend_before_action :set_user
  before_action :set_breadcrumbs
  before_action :authorize_user

  def index
    @identities = @user.identities.order(:provider, :uid)
  end

  def destroy
    identity = @user.identities.find(params[:id])

    if @user.identities.one? && @user.encrypted_password.blank?
      flash[:notice] = 'You cannot remove your last identity because your account has no password.'
    else
      identity.destroy
      flash[:notice] = 'Identity removed.'
    end

    redirect_to user_identities_path(@user)
  end

  private

  def set_user
    @user = User.friendly.find(params[:user_id])
  end

  def authorize_user
    handle_error(:forbidden) && return unless current_user == @user
  end

  def set_breadcrumbs
    add_base_breadcrumbs('users')
    @breadcrumbs += [{ name: @user.name, url: user_path(@user) }, { name: 'Manage identities' }]
  end
end
