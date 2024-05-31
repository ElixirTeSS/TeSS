class LocalizationController < ApplicationController

  skip_before_action :authenticate_user!, :authenticate_user_from_token!

  def change_locale
    # Get locale from params into session
    # See also ApplicationController#locale_from_params_or_session
    if params[:locale]
      session[:locale] = params[:locale]
    else
      if session[:locale].to_s == 'en'
        session[:locale] = 'fr'
      else
        session[:locale] = 'en'
      end
    end

    if params[:back_to]
      redirect_to params[:back_to]
    else
      render body: ''
    end
  end

end
