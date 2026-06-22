class GroupPolicy < ResourcePolicy

  def index?
    true
  end

  def show?
    see? || @user&.is_admin?
  end

  def edit?
    manage?
  end

  def create?
    # Do not allow creations via API and only admin role can create group
    !request_is_api? && @user&.is_admin?
  end

  def update?
    !request_is_api? && manage?
  end

  def destroy?
    !request_is_api? && @user&.is_admin?
  end

  def manage?
    (see? && owner?) || @user&.is_admin?
  end

  def see?
    @record.users.include?(@user)
  end

  private

  def owner?
    @record.group_memberships.find_by(user: @user)&.owner == true
  end
end
