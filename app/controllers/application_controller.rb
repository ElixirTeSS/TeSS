class ApplicationController < ActionController::Base
  include BreadCrumbs
  include PublicActivity::StoreController

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Should allow token authentication for API calls
  acts_as_token_authentication_handler_for User, except: [:index, :show, :embed, :check_exists, :handle_error, :count, :redirect] #only: [:new, :create, :edit, :update, :destroy]

  # User auth should be required in the web interface as well; it's here rather than in routes so that it
  # doesn't override the token auth, above.
  before_action :authenticate_user!, except: [:index, :show, :embed, :check_exists, :handle_error, :count, :redirect]
  before_action :set_current_user

  # Should prevent forgery errors for JSON posts.
  skip_before_filter :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  # Do some access control - see policies folder for individual policies on models
  include Pundit
  protect_from_forgery

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def pundit_user
    CurrentContext.new(current_user, request)
  end

  def handle_error(status_code = '500')
    status_code = params[:status_code] || status_code # params[:status_code] comes from routes for 500, 503, 422 and 404 errors
    @skip_flash_messages_in_header = true
    if status_code == '500'
      flash[:alert] = 'Our apologies - your request caused an error (status code: 500 Server Error).'
    elsif status_code == '503'
      flash[:alert] = 'Our apologies - the server is temporarily down or unavailable due to maintenance (status code: 503 Service Unavailable).'
    elsif status_code == '422'
      flash[:alert] = 'The request you sent was well-formed but the change you wanted was rejected (status code: 422 Unprocessable Entity).'
    elsif status_code == '404'
      flash[:alert] = 'The requested page could not be found - you may have mistyped the address or the page may have moved (status code: 404 Not Found).'
    end
    respond_to do |format|
      format.html  { render 'static/error.html',
                            :status => status_code}

      # format.json  { head status }
      format.json { render :json => flash,
                           :status => status_code}
    end
  end

  def test_url
    body = {}

    begin
      res = HTTParty.get(params[:url], { timeout: 5 })
      body = { code: res.code, message: res.message }
    rescue StandardError
      body = { message: 'Could not access the given URL' }
    end

    respond_to do |format|
      format.json { render json: body }
    end
  end

  private

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:alert] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    handle_error(:forbidden)
  end

  def set_current_user
    User.current_user = current_user
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me, :publicize_email) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def allow_embedding
    response.headers.delete 'X-Frame-Options'
  end

  def look_for_topics(suggestible)
    if suggestible.scientific_topic_names.length == 0 and suggestible.edit_suggestion.nil?
      EditSuggestionWorker.perform_in(1.second,[suggestible.id,suggestible.class.name])
    end
  end
end
