class CookiesController < ApplicationController
  skip_before_action :authenticate_user!, :authenticate_user_from_token!
  before_action :set_cookie_consent_object

  def consent
    respond_to do |format|
      format.html
    end
  end

  def set_consent
    @cookie_consent.level = cookie_params[:allow]
    unless @cookie_consent.level # Invalid option will be set to `nil`
      flash[:error] = "Invalid consent option"
    end

    respond_to do |format|
      format.html { redirect_back(fallback_location: cookies_consent_path) }
    end
  end

  private

  def set_cookie_consent_object
    @cookie_consent = CookieConsent.new(cookies)
  end

  def cookie_params
    params.permit(:allow)
  end
end
