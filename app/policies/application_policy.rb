class ApplicationPolicy
  attr_reader :user, :record
  attr_accessor :request

  # def initialize(user, record)
  #   raise Pundit::NotAuthorizedError, "User must be logged in" unless user
  #   @user = user
  #   @record = record
  # end

  def initialize(context, record)
    raise Pundit::NotAuthorizedError, "User must be logged in" unless context.user
    @user = context.user
    @request = context.request
    @record = record
  end

  def index?
    true
  end

  def show?
    true
    # scope.where(:id => record.id).exists?
  end

  def create?
    # Only admin, api_user or curator roles can create
    #@user.has_role?(:admin) or @user.has_role?(:api_user) or @user.has_role?(:curator)
    # Any registered user user can create
    !@user.role.blank?
  end

  def new?
    create?
  end

  def update?
    # Admin role can update/destroy any object, other roles can only update objects they created
    return true if @user.is_admin? # allow admin roles for all requests - UI and API

    if request_is_api?(@request) #is this an API action - allow api_user roles only
      if @user.has_role?(:api_user) and @user.is_owner?(@record) # check ownership
          return true
      else
        return false
      end
    end

    if @user.is_owner?(@record) # check ownership
      return true
    else
      return false
    end
  end

  def edit?
    update?
  end

  def destroy?
    update?
  end

  def request_is_api?(request)
    return false if request.nil?
    return ((request.post? or request.put? or request.patch?) and request.format.json?)
  end

  def scope
    Pundit.policy_scope!(user, record.class)
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end
end
