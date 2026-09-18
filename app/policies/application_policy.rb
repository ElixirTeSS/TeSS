# Base Pundit policy for the application.
#
# ApplicationPolicy implements the default authorization rules shared by
# most resources (index/show allowed to everyone, create/update/destroy
# restricted to admins via #manage?), plus the shared logic for
# space-scoped visibility (#shown?) used to hide records belonging to
# private Space objects from users who aren't members of one of that
# space's groups.
#
# Individual resource policies (e.g. SpacePolicy, GroupPolicy) subclass
# this and override individual query methods as needed.
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

  # Builds a new policy instance for a given context/record pair.
  #
  # context:: an object responding to +#user+ and +#request+ (see
  #           ApplicationController#pundit_user), providing the current
  #           user and the current HTTP request.
  # record::  the model instance (or class, for +new?+/+create?+ checks)
  #           being authorized. If it responds to +#space+, or is itself a
  #           Space, that space is used to determine private-space
  #           visibility.
  def initialize(context, record)
    @user = context.user
    @request = context.request
    @record = record
    @space = nil
    @space = record.space if record.respond_to?(:space)
    @space = record if record.instance_of?(Space)
  end

  # Returns:: +true+ by default; every record may be listed.
  def index?
    true
  end

  # Returns:: +true+ by default; every record may be shown.
  def show?
    true
  end

  # Returns:: +true+ if there is a logged-in user.
  def create?
    @user
  end

  # Returns:: the result of #create?.
  def new?
    create?
  end

  # Returns:: the result of #manage?.
  def update?
    manage?
  end

  # Returns:: the result of #update?.
  def edit?
    update?
  end

  # Returns:: the result of #manage?.
  def destroy?
    manage?
  end

  # "manage" isn't actually an action, but the "destroy?" and "update?" policies delegate to this method.
  #
  # Returns:: +true+ if the current user is an admin.
  def manage?
    @user&.is_admin?
  end

  # Returns:: +true+ if the current user has the :curator, :admin, or
  #           :scraper_user role (globally or within the current space).
  def curators_and_admin
    user_has_role?(:curator, :admin, :scraper_user)
  end

  # Returns:: the default Pundit policy scope for the record's class.
  def scope
    Pundit.policy_scope!(user, record.class)
  end

  # Determines whether the record should be visible to the current user,
  # considering space privacy and resource approval status.
  #
  # Rules:
  # * Space accessibility:
  #   - Public records or records outside private spaces are accessible.
  #   - Private space records are accessible only to authenticated admins 
  #     or members of the space's groups (in the current space scope).
  # * Approval status (when `material_under_admin_approval` is enabled):
  #   - Approved records follow space accessibility rules.
  #   - Unapproved records require BOTH space accessibility AND one of:
  #     * Site administrator privileges;
  #     * Space administrator privileges;
  #     * Record ownership (@record.user_id == @user.id).
  #
  # Returns:: +true+ or +false+.
  def shown?
    return true if global_admin_role?
    return false unless space_accessible?
    return true unless approval_enabled? && @record.respond_to?(:approved?) && !@record.approved?

    unapproved_accessible?
  end

  # Default Pundit policy scope class.
  #
  # Simply returns the given scope unfiltered; subclasses/resource-specific
  # scopes should override #resolve to apply additional filtering.
  class Scope
    attr_reader :user, :scope

    # context:: an object responding to +#user+, providing the current
    #           user.
    # scope::   the ActiveRecord relation/class to scope.
    def initialize(context, scope)
      @user = context.user
      @scope = scope
    end

    # Returns:: the unfiltered +scope+.
    def resolve
      scope
    end
  end

  private

  # Returns:: +true+ if the current request is a JSON POST/PUT/PATCH
  #           (i.e. an API write request).
  def request_is_api?
    !!@request && ((@request.post? || @request.put? || @request.patch?) && @request.format.json?)
  end

  # Returns:: +true+ if this is an API write request made by a user with
  #           the :scraper_user role.
  def scraper?
    request_is_api? && @user&.has_role?(:scraper_user)
  end

  # Check if the user has any of the given roles.
  # If we're in a space, also check they have any of those roles in the context of the space.
  #
  # roles:: one or more Symbol role keys to check.
  #
  # Returns:: +true+ if the user holds any of the given roles globally, or
  #           within the current space, +false+ otherwise (including when
  #           there is no current user).
  def user_has_role?(*roles)
    return false if @user.nil?
    roles.any? { |r| @user.has_role?(r) } ||
      (@space && roles.any? { |r| @user.has_space_role?(@space, r) })
  end

  def global_admin_role?
    curators_and_admin
  end

  def space_accessible?
    return true if @space == nil
    return true if !@space.is_private
    return false unless @user # and so if space is private
    if @space == Space.current_space || @record == @space
      return @user.groups.where(id: @space.groups).any?
    end

    return false
  end

  def approval_enabled?
    TeSS::Config.feature['material_under_admin_approval'] || TeSS::Config.feature['event_under_admin_approval']
  end

  def unapproved_accessible?
    return false unless @user

    (@record.respond_to?(:user_id) && @record.user_id == @user.id) ||
    (@space&.respond_to?(:admin?) && @space.admin?(@user))
  end
end