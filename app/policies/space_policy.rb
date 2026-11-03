# Pundit policy for Space.
#
# Visibility of a space is delegated to ApplicationPolicy#shown? (private
# spaces are only visible to members of one of their groups, or admins);
# editing is additionally granted to the space's owner and its
# space-level admins.
class SpacePolicy < ApplicationPolicy

  # Returns:: the result of #shown?.
  def show?
    shown?
  end

  # Returns:: the result of #manage?.
  def create?
    manage?
  end

  # Returns:: +true+ if there is a current user who either owns the space,
  #           holds the :admin SpaceRole for it, or is a global admin
  #           (#manage?) — and the space is #shown? to them.
  def edit?
    @user && (@user.is_owner?(@record) || @user.has_space_role?(@record, :admin) || manage?) && shown?
  end

  # Returns:: the result of #edit?.
  def update?
    edit?
  end

  # Returns:: +true+ if the current user is a global admin.
  def manage?
    @user&.is_admin?
  end

  # Returns:: the result of #manage?.
  def destroy?
    manage?
  end

end