class TessDevise::RegistrationsController < Devise::RegistrationsController
  # Inspired by http://stackoverflow.com/questions/3546289/override-devise-registrations-controller
  before_action :check_captcha, only: :create
  before_action :set_breadcrumbs, only: :edit

  # Set the after update path to be user's show page
  # instead the default root_path
  def after_update_path_for(resource)
    user_path(resource)
  end

  protected

  def update_resource(resource, params)
    if current_user.using_omniauth?
      params.delete(:current_password)
      resource.update_without_password(params)
    else
      super
    end
  end

  private

  # Pinched from https://github.com/plataformatec/devise/wiki/How-To:-Use-Recaptcha-with-Devise
  def check_captcha
    if !Rails.application.secrets.recaptcha[:sitekey].blank? && !verify_recaptcha
      self.resource = resource_class.new sign_up_params
      respond_with_navigational(resource) { render :new }
    end
  end

  def set_breadcrumbs
    add_base_breadcrumbs('users')
    @breadcrumbs += [{ name: @user.name, url: user_path(@user) }, { name: 'Manage Account' }]
  end
end
