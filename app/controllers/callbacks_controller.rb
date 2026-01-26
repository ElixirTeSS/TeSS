# The controller for callback actions
class CallbacksController < Devise::OmniauthCallbacksController

  Devise.omniauth_configs.each do |provider, config|
    define_method(provider) do
      handle_callback(provider, config)
    end
  end

  private

  def handle_callback(provider, config)
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if request.env['omniauth.params'] && request.env['omniauth.params']['space_id']
      space = Space.find_by_id(request.env['omniauth.params']['space_id'])
    end

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
      sign_in(scope, resource, {})
      redirect_to_space(after_sign_in_path_for(@user), space)
    end
  end

  private

  def redirect_to_space(path, space)
    if space&.is_subdomain?
      port_part = ''
      port_part = ":#{request.port}" if (request.protocol == "http://" && request.port != 80) ||
                                        (request.protocol == "https://" && request.port != 443)
      redirect_to URI.join("#{request.protocol}#{space.host}#{port_part}", path).to_s, allow_other_host: true
    else
      redirect_to path
    end
  end

end