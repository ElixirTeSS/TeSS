class ApplicationController < ActionController::Base
  include PublicActivity::StoreController

  before_action :configure_permitted_parameters, if: :devise_controller?

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # Should allow token authentication for API calls
  acts_as_token_authentication_handler_for User, except: [:index, :show, :check_exists] #only: [:new, :create, :edit, :update, :destroy]

  # User auth should be required in the web interface as well; it's here rather than in routes so that it
  # doesn't override the token auth, above.
  before_action :authenticate_user!, except: [:index, :show, :check_exists]

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

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def solr_search(model_name, search_params='', selected_facets=[], page=1, sort_by=nil)
    model_name.search do

      fulltext search_params
      #Set the search parameter
      #Disjunction clause
      facets = []

      any do
        #Set all facets
        selected_facets.each do |facet_title, facet_value|
          if facet_title != 'include_expired'
            any do
              #Conjunction clause
              facets << with(facet_title, facet_value)
            end
          end
        end
      end

      if sort_by
        case sort_by
          when 'early'
            # Sort by start date asc
            order_by(:start, :asc)
          when 'late'
            # Sort by start date desc
            order_by(:start, :desc)
          when 'rel'
            # Sort by relevance
          when 'mod'
            # Sort by last modified
            order_by(:updated_at, :asc)
          else
            order_by :title, sort_by.to_sym
        end
      elsif model_name == Event
        order_by(:start, :asc)
      end

      if !page.nil? and page != '1'
        paginate :page => page
      end

      #Go through the selected facets and apply them and their facet_values
      if model_name == Event
        facet 'start'
        unless selected_facets.keys.include?('include_expired') and selected_facets['include_expired'] == true
          with('start').greater_than(Time.zone.now)
        end
      end

      facet_fields.each do |ff|
        facet ff, exclude: facets
      end
    end
  end

  # # Check if user is owner of a resource or user is admin
  # def check_permissions?(user, resource)
  #   return false if user.nil? or resource.nil?
  #   return false if !resource.respond_to?("owner".to_sym)
  #   return true if user.is_admin?
  #
  #   # Else the user needs to be the owner of the resource
  #   if user == resource.owner
  #     return true
  #   else
  #     return false
  #   end
  # end
  # helper_method :check_permissions?

  def determine_resource
    #Find out the resource object being requested
    resource_id = params[:id]
    return nil if resource_id.blank?

    return controller_name.classify.constantize.find(resource_id)
  end

end
