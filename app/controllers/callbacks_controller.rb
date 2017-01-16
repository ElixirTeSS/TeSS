class CallbacksController < Devise::OmniauthCallbacksController
  # It's not clear which, if any, of these are actually called.
  def elixir_aai
    Logger.info("Got to the callbacks controller after auth (elixir_aai)!")
    @user = User.from_omniauth(request.env["omniauth.auth"])
    sign_in_and_redirect @user
  end

  def omniauth_callbacks
    Logger.info("Got to the callbacks controller after auth!")
    flash[:notice] = "Successful AAI authentication: #{@action}!"
    @user = User.from_omniauth(request.env["omniauth.auth"])
    Logger.info("WIBBLE: #{omniauth.auth.inspect}")
    sign_in_and_redirect @user
  end
end