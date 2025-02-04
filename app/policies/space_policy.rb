class SpacePolicy < ApplicationPolicy

  def create?
    @user && @user.has_role?(:admin)
  end

  def edit?
    @user && (@user.is_owner?(@record) || manage?)
  end

  def update?
    edit?
  end

  def manage?
    @user && @user.is_admin?
  end

end
