require 'private_address_check'
require 'private_address_check/tcpsocket_ext'

# Base controller for the whole application.
#
# ApplicationController centralizes cross-cutting concerns shared by every
# controller in TeSS: authentication (Devise + token auth), authorization
# (Pundit), multi-space resolution, error rendering, and a couple of small
# utility endpoints (+test_url+, +job_status+).
#
# All other controllers should inherit from this class rather than directly
# from <tt>ActionController::Base</tt>.
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
  before_action :set_current_user
  before_action :authenticate_user!, except: [:index, :show, :embed, :calendar, :check_exists, :handle_error, :count, :redirect]
  before_action :set_current_space

  # Should prevent forgery errors for JSON posts.
  skip_before_action :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  # Do some access control - see policies folder for individual policies on models
  include Pundit::Authorization

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Builds the context object passed to every Pundit policy.
  #
  # Bundling +current_user+ together with the +request+ lets policies make
  # decisions based on how the request was made (e.g. JSON API vs HTML),
  # in addition to who is making it.
  #
  # Returns:: a Pundit::CurrentContext wrapping the current user and request.
  def pundit_user
    Pundit::CurrentContext.new(current_user, request)
  end

  # Renders a generic error page/response for a given HTTP status code.
  #
  # Accepts either a numeric or symbolic status code (e.g. :forbidden,
  # :not_found) and renders the appropriate HTML error page, or a JSON/JSON:API
  # error payload depending on the requested format. Falls back to a
  # translated default message when none is supplied.
  #
  # status_code:: Integer or Symbol HTTP status code (default: 500). May be
  #               overridden by the <tt>params[:status_code]</tt> value set by
  #               the routes for 500, 503, 422 and 404 errors.
  # message::     optional String error message to display; defaults to a
  #               localized message for the given status code.
  def handle_error(status_code = 500, message = nil)
    status_code = (params[:status_code] || status_code) # params[:status_code] comes from routes for 500, 503, 422 and 404 errors
    if status_code.is_a?(Symbol) # Convert :forbidden, :not_found, etc. to 403, 404 etc.
      status_code = :unprocessable_content if status_code == :unprocessable_entity
      status_code = Rack::Utils::SYMBOL_TO_STATUS_CODE[status_code] || status_code
    end

    if message.blank?
      message = t("errors.#{status_code}",
                  default: "#{TeSS::Config.site['title_short']} encountered an unexpected error: #{status_code}")
    end

    status_code = status_code.to_i
    @message = message
    respond_to do |format|
      format.html { render 'static/error', status: status_code }
      format.json { render json: { error: { message: message, code: status_code } }, status: status_code }
      format.json_api { render json: { error: { message: message, code: status_code } }, status: status_code }
      format.any { head status_code }
    end
  end

  # Checks whether a given URL is reachable, guarding against SSRF by only
  # allowing connections to public addresses (via PrivateAddressCheck).
  #
  # Expects <tt>params[:url]</tt> to contain the URL to test. Responds with a
  # JSON body describing the outcome (HTTP code on success, or an explanatory
  # message on failure/invalid URL).
  def test_url
    body = {}

    begin
      uri = URI.parse(params[:url]) rescue nil
      if uri && (uri.scheme == 'http' || uri.scheme == 'https')
        PrivateAddressCheck.only_public_connections do
          res = HTTParty.get(uri.to_s, timeout: 5, format: :plain)
          body = { code: res.code, message: 'OK' }
        end
      else
        body = { message: 'Invalid URL - Make sure the URL starts with "https://" or "http://"' }
      end
    rescue PrivateAddressCheck::PrivateConnectionAttemptedError, Net::OpenTimeout, Net::ReadTimeout, SocketError,
      Errno::ECONNREFUSED, Errno::EHOSTUNREACH, OpenSSL::SSL::SSLError, URI::InvalidURIError
      body = { message: 'Could not access the given URL' }
    end

    respond_to do |format|
      format.json { render json: body }
    end
  end

  # Returns the status of a background job (Sidekiq) as JSON.
  #
  # Expects <tt>params[:id]</tt> to be the Sidekiq job id. Responds with
  # <tt>404</tt> and <tt>{ status: 'not-found' }</tt> if no status is found
  # for that id.
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

  # Checks whether the given feature is enabled for the current space.
  #
  # feature:: String or Symbol feature key (see Space::FEATURES).
  #
  # Returns:: +true+ or +false+.
  def feature_enabled?(feature)
    Space.current_space.feature_enabled?(feature)
  end

  helper_method :feature_enabled?

  # before_action-style guard that raises a routing error (resulting in a
  # 404) when the given feature is disabled globally via TeSS::Config.
  #
  # feature:: String or Symbol feature key; defaults to the current
  #           controller's name.
  #
  # Raises:: ActionController::RoutingError if the feature is explicitly
  #          disabled in the application configuration.
  def ensure_feature_enabled(feature = controller_name)
    if TeSS::Config.feature.key?(feature) && !TeSS::Config.feature[feature]
      raise ActionController::RoutingError.new('Feature not enabled')
    end
  end

  # Rescue handler for Pundit::NotAuthorizedError.
  #
  # Renders a localized "forbidden" error message based on the policy and
  # query that denied access.
  #
  # exception:: the raised Pundit::NotAuthorizedError.
  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    handle_error(:forbidden, t("#{policy_name}.#{exception.query}", scope: 'pundit', default: :default))
  end

  # before_action that resolves and stores the Space matching the current
  # request host (or the default space if the +spaces+ feature is disabled),
  # and redirects unauthorized users away from private spaces they cannot
  # access.
  def set_current_space
    Space.current_space = TeSS::Config.feature['spaces'] ? Space.find_by_host(request.host) : Space.default
    # if the current_space is a specific space (not the default one), we check if the user can access it
    if TeSS::Config.feature['spaces'] && Space.current_space != Space.default
      unless policy(Space.current_space).shown?
        if current_user
          flash[:alert] = "You are not authorized to access this page."
          redirect_to TeSS::Config.base_url, allow_other_host: true
        else
          flash[:alert] = "Sign in to access this page."
          redirect_to TeSS::Config.base_url + '/users/sign_in', allow_other_host: true
        end
      end
    end
  end

  # Returns:: the Space resolved for the current request by #set_current_space.
  def current_space
    Space.current_space
  end

  helper_method :current_space

  # before_action that stores the current user on the User class (for
  # convenience access outside the request cycle) and reports the user to
  # Sentry, when Sentry is enabled.
  def set_current_user
    User.current_user = current_user
    if TeSS::Config.sentry_enabled?
      Sentry.set_user(current_user ? { id: current_user.id, username: current_user.username } : {})
    end
  end

  # Looks up the country of the current request's IP address.
  #
  # Uses the <tt>MOCK_IP</tt> environment variable outside of production so
  # geolocation can be tested locally.
  #
  # Returns:: a country code/name Hash entry from the Locator lookup, or
  #           +nil+ if it could not be determined.
  def current_user_country
    remote_ip = ENV.fetch('MOCK_IP') { Rails.env.production? ? request.remote_ip : '130.88.0.0' }
    Locator.instance.lookup(remote_ip)&.dig('country')
  end

  # Returns:: +true+ if the current request's country is in the configured
  #           list of blocked countries, +false+ otherwise.
  def from_blocked_country?
    return unless TeSS::Config.blocked_countries.present?
    user_country = current_user_country
    return unless user_country
    TeSS::Config.blocked_countries.include?(user_country['iso_code'].downcase)
  end

  helper_method :current_user_country, :from_blocked_country?

  protected

  # Configures the extra parameters Devise should permit for sign up,
  # sign in and account update, beyond its defaults.
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |u| u.permit(:username, :email, :password, :password_confirmation,
                                                                :remember_me, :publicize_email, :processing_consent)
    end
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) do |u| u.permit(:username, :email, :password,
                                                                       :password_confirmation, :current_password)
    end
  end

  # Removes the <tt>X-Frame-Options</tt> header so the response can be
  # embedded in an iframe on another site.
  def allow_embedding
    response.headers.delete 'X-Frame-Options'
  end
end
