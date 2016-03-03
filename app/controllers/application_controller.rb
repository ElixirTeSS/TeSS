class ApplicationController < ActionController::Base

  require 'bread_crumbs'

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

  # Prevent all but admins from creating events
  # !!!!!! Make sure this method is always invoked in conjunction with authenticate_user!
  # otherwise access control loopholes will be opened
  before_action :check_authorised, except: [:index, :show, :check_exists]

  #def after_sign_in_path_for(resource)
  #  root_path
  #end

  #def after_sign_out_path_for(resource_or_scope)
  #  request.referrer
  #end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def solr_search(model_name, search_params='', facet_fields=[], selected_facets=[], page=1, sort_by=nil)
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

  def check_authorised
    user = current_user || User.find_by_authentication_token(params[:user_token])
    if (user.nil?)
      return # user has not been logged in yet!
    else
      # In most cases we'd need to check if role is admin, registered user or api_user
      check_admin_or_api_or_registered_user(user)
    end
  end

  def request_is_api?
    return ((request.post? or request.put? or request.patch?) and request.format.json?)
  end

  def closed_route
    if !((request.post? or request.put? or request.patch?) and request.format.json?)
      head(403)
      #redirect_to :back, notice: "Sorry, you're not allowed to view that page."
    end
    #rescue ActionController::RedirectBackError
    #  redirect_to root_path, notice: "Sorry, you're not allowed to view that page."
  end

  def check_admin_or_api_user(user)
    if !user.nil?
      return if user.is_admin? # allow admins for all requests - UI and API, and all methods
      if request_is_api? #is an API action - allow api_user accounts such as scrapers
        if user.is_api_user?
          if [:edit, :update, :destroy].include?(action_name) # for some methods check ownership
            return if check_permissions?(user, determine_resource)
          else
            return
          end
        else #return 403 Forbidden status code
          head(403)
        end
      end
    end
    # Should not really ever come to here
    flash[:error] = "Sorry, you're not allowed to view that page."
    redirect_to root_path
  end

  def check_admin_or_api_or_registered_user(user)
    if !user.nil?
      return if user.is_admin? # allow admins for all requests - UI and API
      if request_is_api? #is an API action - allow api_user accounts such as scrapers
        if user.is_api_user?
          if [:edit, :update, :destroy].include?(action_name) # for some methods check ownership
            return if check_permissions?(user, determine_resource)
          else
            return
          end
        else #return 403 Forbidden status code
          head(403)
        end
      end
      if user.is_registered_user? or user.is_api_user? # Not an API request, so allow registered users and API users only if they are the owner of the resource
        if [:edit, :update, :destroy].include?(action_name) # for some methods check ownership
          return if check_permissions?(user, determine_resource)
        else
          return
        end
      end
    end
    # Should not really ever come to here
    flash[:error] = "Sorry, you're not allowed to view that page."
    redirect_to root_path
  end

  # Check if user is owner of a resource or user is admin
  def check_permissions?(user, resource)
    return false if user.nil? or resource.nil?
    return false if !resource.respond_to?("owner".to_sym)
    return true if user.is_admin?

    # Else the user needs to be the owner of the resource
    if user == resource.owner
      return true
    else
      return false
    end
  end
  helper_method :check_permissions?

  def determine_resource
    #Find out the resource object being requested
    resource_id = params[:id]
    return nil if resource_id.blank?

    return controller_name.classify.constantize.find(resource_id)
  end

end
