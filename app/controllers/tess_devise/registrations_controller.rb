class TessDevise::RegistrationsController < Devise::RegistrationsController
  # Inspired by http://stackoverflow.com/questions/3546289/override-devise-registrations-controller
  before_action :check_captcha, only: :create

  # Set the after update path to be user's show page
  # instead the default root_path
  def after_update_path_for(resource)
    user_path(resource)
  end

  private

  # Pinched from https://github.com/plataformatec/devise/wiki/How-To:-Use-Recaptcha-with-Devise
  def check_captcha
    unless !Rails.application.secrets.captcha_sitekey.blank? && verify_recaptcha
      self.resource = resource_class.new sign_up_params
      respond_with_navigational(resource) { render :new }
    end
  end
end
