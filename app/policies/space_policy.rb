class SpacePolicy < ApplicationPolicy

  def show?
    shown?
  end

  def create?
    manage?
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
    manage?
  end

end
