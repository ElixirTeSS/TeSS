require 'private_address_check'
require 'private_address_check/tcpsocket_ext'

# The controller for actions related to the core application
class ApplicationController < ActionController::Base
  include BreadCrumbs
  include PublicActivity::StoreController

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Should allow token authentication for API calls
  acts_as_token_authentication_handler_for User, except: [:index, :show, :embed, :calendar, :check_exists, :handle_error, :count,
                                                          :redirect] #only: [:new, :create, :edit, :update, :destroy]

  # User auth should be required in the web interface as well; it's here rather than in routes so that it
  # doesn't override the token auth, above.
  before_action :authenticate_user!, except: [:index, :show, :embed, :calendar, :check_exists, :handle_error, :count, :redirect]
  before_action :set_current_user

  # Should prevent forgery errors for JSON posts.
  skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  # Do some access control - see policies folder for individual policies on models
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def pundit_user
    Pundit::CurrentContext.new(current_user, request)
  end

  def handle_error(status_code = 500, message = nil)
    status_code = (params[:status_code] || status_code) # params[:status_code] comes from routes for 500, 503, 422 and 404 errors
    if status_code.is_a?(Symbol) # Convert :forbidden, :not_found, etc. to 403, 404 etc.
      status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status_code] || status_code
    end

    if message.blank?
      message = t("errors.#{status_code}",
                  default: "#{TeSS::Config.site['title_short']} encountered an unexpected error: #{status_code}")
    end

    status_code = status_code.to_i
    @message = message
    respond_to do |format|
      format.html  { render 'static/error', status: status_code}
      format.json { render json: { error: { message: message, code: status_code } }, status: status_code }
      format.json_api { render json: { error: { message: message, code: status_code } }, status: status_code }
    end
  end

  def test_url
    body = {}

    begin
      uri = URI.parse(params[:url]) rescue nil
      if uri && (uri.scheme == 'http' || uri.scheme == 'https')
        PrivateAddressCheck.only_public_connections do
          res = HTTParty.get(uri.to_s, { timeout: 5 })
          body = { code: res.code, message: res.message }
        end
      else
        body = { message: 'Invalid URL - Make sure the URL starts with "https://" or "http://"' }
      end
    rescue PrivateAddressCheck::PrivateConnectionAttemptedError, Net::OpenTimeout, SocketError, Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH
      body = { message: 'Could not access the given URL' }
    end

    respond_to do |format|
      format.json { render json: body }
    end
  end

  def job_status
    begin
      status = Sidekiq::Status::status(params[:id])

      if status.present?
        respond_to do |format|
          format.json { render json: { status: status } }
        end
      else
        respond_to do |format|
          format.json { render json: { status: 'not-found' }, status: 404 }
        end
      end
    end
  end

  private

  def feature_enabled?(feature = controller_name)
    if TeSS::Config.feature.key?(feature) && !TeSS::Config.feature[feature]
      raise ActionController::RoutingError.new('Feature not enabled')
    end
  end

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    handle_error(:forbidden, t("#{policy_name}.#{exception.query}", scope: 'pundit', default: :default))
  end

  def set_current_user
    User.current_user = current_user
    if TeSS::Config.sentry_enabled?
      Sentry.set_user(current_user ? { id: current_user.id, username: current_user.username } : {})
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |u| u.permit(:username, :email, :password, :password_confirmation,
                                                                :remember_me, :publicize_email, :processing_consent)
    end
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) do |u| u.permit(:username, :email, :password,
                                                                       :password_confirmation, :current_password)
    end
  end

  def allow_embedding
    response.headers.delete 'X-Frame-Options'
  end
end
