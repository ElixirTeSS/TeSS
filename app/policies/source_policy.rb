# frozen_string_literal: true

class SourcePolicy < ScrapedResourcePolicy
  def show?
    user_management? || administration?
  end

  alias orig_manage? manage?
  def manage?
    (user_management? && !@record.approval_requested?) || administration?
  end

  def index?
    administration?
  end

  def create?
    if TeSS::Config.feature['user_source_creation']
      super
    else
      administration?
    end
  end

  def approve?
    @user&.has_role?(:admin)
  end

  def request_approval?
    user_management?
  end

  private

  # Can edit sources for any content provider
  def administration?
    curators_and_admin
  end

  def user_management?
    if TeSS::Config.feature['user_source_creation']
      orig_manage?
    else
      false
    end
  end

  def curators_and_admin
    @user && (
      @user.has_role?(:curator) ||
        @user.has_role?(:admin) ||
        @user.has_role?(:scraper_user))
  end
end
