class ApplicationController < ActionController::Base
  include PublicActivity::StoreController

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :check_server

  attr_reader :test_server

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Should allow token authentication for API calls
  acts_as_token_authentication_handler_for User, except: [:index, :show, :embed, :check_exists, :handle_error] #only: [:new, :create, :edit, :update, :destroy]

  # User auth should be required in the web interface as well; it's here rather than in routes so that it
  # doesn't override the token auth, above.
  before_action :authenticate_user!, except: [:index, :show, :embed, :check_exists, :handle_error]
  before_filter :set_current_user

  # Should prevent forgery errors for JSON posts.
  skip_before_filter :verify_authenticity_token, :if => Proc.new { |c| c.request.format == 'application/json' }

  # Do some access control - see policies folder for individual policies on models
  include Pundit
  protect_from_forgery

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def pundit_user
    CurrentContext.new(current_user, request)
  end

  def handle_error(status_code = 500)
    status_code = params[:status_code] || status_code # params[:status_code] comes from routes for 500, 503, 422 and 404 errors
    @skip_flash_messages_in_header = true
    if status_code == "500"
      flash[:alert] = "Our apology - your request caused an error (status code: 500 Server Error)."
    elsif status_code == "503"
      flash[:alert] = "Our apology - the server is temporarily down or unavailable due to maintenance (status code: 503 Service Unavailable)."
    elsif status_code == "422"
      flash[:alert] = "The request you sent was well-formed but the change you wanted was rejected (status code: 422 Unprocessable Entity)."
    elsif status_code == "404"
      flash[:alert] = "The requested page could not be found - you may have mistyped the address or the page may have moved (status code: 404 Not Found)."
    end
    respond_to do |format|
      format.html  { render 'static/error.html',
                            :status => status_code}

      # format.json  { head status }
      format.json { render :json => flash,
                           :status => status_code}
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

  def determine_resource
    #Find out the resource object being requested
    resource_id = params[:id]
    return nil if resource_id.blank?

    return controller_name.classify.constantize.find(resource_id)
  end

  def check_server
    @test_server =  false
    test_ip = Rails.application.secrets.test_server_ip
    if !test_ip.nil?
      ips = Socket.ip_address_list.collect {|x| x.ip_address }
      #hostname = `hostname -i`.chomp! # I have naughtily assumed this is a linux box
      #if hostname == test_ip
      if ips.include? test_ip
        @test_server = true
      end
    end
  end
end
