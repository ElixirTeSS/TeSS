# The controller for callback actions
class CallbacksController < Devise::OmniauthCallbacksController

  # handle provider oidc - AAF (Aus)
  def oidc
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.new_record?
      # new user
      begin
        save_result = @user.save
        if !save_result
          Rails.logger.debug "CallbacksController.oidc2: #{@user.errors.full_messages.to_s}"
          if @user.errors.full_messages.size > 0
            raise @user.errors.full_messages.first.to_s
          else
            raise "unknown error"
          end
        end

        sign_in @user
        flash[:notice] = "#{I18n.t('devise.registrations.signed_up')} Please ensure your profile is correct."
        redirect_to edit_user_path(@user)
      rescue Exception => e
        flash[:notice] = "Login failed: #{e.message.to_s}"
        redirect_to new_user_session_path
      end
    else
      sign_in_and_redirect @user
    end

  end

  # handle provider oidc2 - Tuakiri (NZ)
  def oidc2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.new_record?
      # new user
      begin
        save_result = @user.save
        if !save_result
          Rails.logger.debug "CallbacksController.oidc2: #{@user.errors.full_messages.to_s}"
          if @user.errors.full_messages.size > 0
            raise @user.errors.full_messages.first.to_s
          else
            raise "unknown error"
          end
        end

        sign_in @user
        flash[:notice] = "#{I18n.t('devise.registrations.signed_up')} Please ensure your profile is correct."
        redirect_to edit_user_path(@user)
      rescue Exception => e
        flash[:notice] = "Login failed: #{e.message.to_s}"
        redirect_to new_user_session_path
      end
    else
      # existing user
      sign_in_and_redirect @user
    end

  end

end