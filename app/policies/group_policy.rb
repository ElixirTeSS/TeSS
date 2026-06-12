class GroupPolicy < ScrapedResourcePolicy

  def index?
    true
  end

  def show?
    true
  end

  def edit?
    @user&.is_admin?
  end

  def create?
    # Do not allow creations via API and only admin role can create group
    !request_is_api? && @user&.is_admin?
  end

  def update?
    # Do not allow creations via API and only admin role can create group
    !request_is_api? && @user&.is_admin?
  end

  def destroy?
    @user&.is_admin?
  end

end
