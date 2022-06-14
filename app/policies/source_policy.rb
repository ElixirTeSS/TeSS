class SourcePolicy < ApplicationPolicy

  def show?
    @user && !@user.role.blank?
  end

  def manage?
    @user && (
      @user.has_role?(:curator) ||
      @user.has_role?(:admin) ||
      @user.has_role?(:scraper_user))
  end

  def index?
    show?
  end

  def new?
    manage?
  end

  def create?
    manage?
  end

end
