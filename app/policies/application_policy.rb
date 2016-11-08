class ApplicationPolicy

  attr_reader :user, :record
  attr_accessor :request

  # def initialize(user, record)
  #   raise Pundit::NotAuthorizedError, "User must be logged in" unless user
  #   @user = user
  #   @record = record
  # end

  # For tricks on how to bundle an extra object and pass it to policy
  # in addition to user and record object - see
  # http://stackoverflow.com/questions/28216678/pundit-policies-with-two-input-parameters
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
    # Admin role can update/destroy any object
    # See individual policies for how owners, API users, and curators can update records.
    return true if @user.is_admin?
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

    def initialize(context, scope)
      @user = context.user
      @scope = scope
    end

    def resolve
      scope
    end
  end

end
