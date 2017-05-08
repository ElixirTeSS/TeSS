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
    # Only admin, scraper_user or curator roles can create
    #@user.has_role?(:admin) or @user.has_role?(:scraper_user) or @user.has_role?(:curator)
    # Any registered user user can create
    @user && !@user.role.blank?
  end

  def new?
    create?
  end

  def update?
    manage?
  end

  def edit?
    update?
  end

  def destroy?
    manage?
  end

  # "manage" isn't actually an action, but the "destroy?" and "update?" policies delegate to this method.
  def manage?
    @user && @user.is_admin?
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
