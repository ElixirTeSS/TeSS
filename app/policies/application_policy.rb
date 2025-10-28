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
  end

  def create?
    @user
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
    @user&.is_admin?
  end

  def curators_and_admin
    user_has_role?(:curator, :admin, :scraper_user)
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

  private

  def request_is_api?
    !!@request && ((@request.post? || @request.put? || @request.patch?) && @request.format.json?)
  end

  def scraper?
    request_is_api? && @user&.has_role?(:scraper_user)
  end

  # Check if the user has any of the given roles.
  def user_has_role?(*roles)
    return false if @user.nil?
    roles.any? { |r| @user.has_role?(r) }
  end

end
