class UserPolicy < ApplicationPolicy

  def index?
    true
  end

  def show?
    # Anyone (not even logged in) can see users' pages, with restrictions in view
    # that owners and admins only can see their authentication token and email
    true
  end

  def create?
    # Do not allow creations via API and only admin role can create users
    !request_is_api?(request) && @user && @user.is_admin?
  end

  def manage?
    # Do not allow updates via API
    # Only admin role can update other users or the users themselves
    !request_is_api?(request) && (@user && (@user == @record || @user.is_admin?))
  end

  def change_token?
    update?
  end

  def change_role?
    @user && @user.is_admin?
  end

  def ban?
    change_role?
  end

  def destroy?
    manage?
  end

end
