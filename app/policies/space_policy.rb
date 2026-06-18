class SpacePolicy < ApplicationPolicy

  def show?
    shown?
  end

  def create?
    @user&.has_role?(:admin)
  end

  def edit?
    @user && (@user.is_owner?(@record) || @user.has_space_role?(@record, :admin) || manage?) && shown?
  end

  def update?
    edit?
  end

  def manage?
    @user&.is_admin?
  end

  def destroy?
    edit?
  end

end
