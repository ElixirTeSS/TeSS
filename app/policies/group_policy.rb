# Pundit policy for Group.
#
# Groups may be seen and managed by their members/owners in addition to
# admins; creation, update and destruction via the JSON API are always
# forbidden regardless of role.
class GroupPolicy < ResourcePolicy

  # Returns:: +true+; the group index is visible to everyone.
  def index?
    true
  end

  # Returns:: +true+ if the current user belongs to the group (#see?) or is
  #           an admin.
  def show?
    see? || @user&.is_admin?
  end

  # Returns:: the result of #manage?.
  def edit?
    manage?
  end

  # Returns:: +true+ if the request is not an API write request and the
  #           current user is an admin. Group creation via the API is never
  #           allowed, and only admins may create groups.
  def create?
    # Do not allow creations via API and only admin role can create group
    !request_is_api? && @user&.is_admin?
  end

  # Returns:: +true+ if the request is not an API write request and
  #           #manage? allows it.
  def update?
    !request_is_api? && manage?
  end

  # Returns:: +true+ if the request is not an API write request and the
  #           current user is either an admin or an owner (#owner?) of the
  #           group.
  def destroy?
    !request_is_api? && (@user&.is_admin? || owner?)
  end

  # Returns:: +true+ if the current user belongs to the group and is one of
  #           its owners, or is an admin.
  def manage?
    (see? && owner?) || @user&.is_admin?
  end

  # Returns:: +true+ if the current user is a member of the group.
  def see?
    @record.users.include?(@user)
  end

  private

  # Returns:: +true+ if the current user's GroupMembership for this group
  #           has the +owner+ flag set.
  def owner?
    @record.group_memberships.find_by(user: @user)&.owner == true
  end
end