# frozen_string_literal: true

# The controller for callback actions
class CallbacksController < Devise::OmniauthCallbacksController
  Devise.omniauth_configs.each do |provider, config|
    define_method(provider) do
      handle_callback(provider, config)
    end
  end

  private

  def handle_callback(provider, _config)
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.new_record?
      # new user
      begin
        save_result = @user.save
        unless save_result
          Rails.logger.debug "CallbacksController.#{provider}: #{@user.errors.full_messages}"
          raise @user.errors.full_messages.first.to_s if @user.errors.full_messages.size.positive?

          raise 'unknown error'

        end

        sign_in @user
        flash[:notice] = "#{I18n.t('devise.registrations.signed_up')} Please ensure your profile is correct."
        redirect_to edit_user_path(@user)
      rescue Exception => e
        flash[:notice] = "Login failed: #{e.message}"
        redirect_to new_user_session_path
      end
    else
      sign_in_and_redirect @user
    end
  end
end
