# The controller for callback actions
class CallbacksController < Devise::OmniauthCallbacksController
  include SpaceRedirect

  Devise.omniauth_configs.each do |provider, config|
    define_method(provider) do
      handle_callback(provider, config)
    end
  end

  private

  def handle_callback(provider, config)
    auth = request.env['omniauth.auth']
    if request.env['omniauth.params'] && request.env['omniauth.params']['space_id']
      space = Space.find_by_id(request.env['omniauth.params']['space_id'])
    end

    if current_user && request.env.dig('omniauth.params', 'link_identity').to_s == '1'
      link_identity(auth, space)
      return
    end

    @user = User.from_omniauth(auth)

    if @user.new_record?
      # new user
      begin
        save_result = @user.save
        unless save_result
          Rails.logger.debug "CallbacksController.#{provider}: #{@user.errors.full_messages.to_s}"
          if @user.errors.full_messages.size > 0
            raise @user.errors.full_messages.first.to_s
          else
            raise "unknown error"
          end
        end

        sign_in @user
        flash[:notice] = "#{I18n.t('devise.registrations.signed_up')} Please ensure your profile is correct."
        redirect_to_space(edit_user_path(@user), space)
      rescue Exception => e
        flash[:notice] = "Login failed: #{e.message.to_s}"
        redirect_to_space(new_user_session_path, space)
      end
    else
      scope = Devise::Mapping.find_scope!(@user)
      sign_in(scope, @user, {})
      redirect_to_space(after_sign_in_path_for(@user), space)
    end
  end

  def link_identity(auth, space)
    identity = Identity.from_omniauth(auth)

    if identity.user == current_user
      flash[:notice] = 'Identity is already linked to your account.'
    elsif identity.user.present?
      flash[:notice] = 'Identity is already linked to another account.'
    else
      identity.user = current_user
      identity.save!
      flash[:notice] = 'Identity linked successfully.'
    end

    redirect_to_space(user_identities_path(current_user), space)
  rescue StandardError => e
    flash[:notice] = "Could not link identity: #{e.message}"
    redirect_to_space(user_identities_path(current_user), space)
  end
end