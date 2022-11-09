class SourcePolicy < ResourcePolicy
  def show?
    manage?
  end

  def manage?
    if TeSS::Config.feature['source_approval']
      super
    else
      administration?
    end
  end

  def index?
    administration?
  end

  def create?
    if TeSS::Config.feature['source_approval']
      super
    else
      administration?
    end
  end

  def approve?
    @user && @user.has_role?(:admin)
  end

  def administration? # Can edit sources for any content provider
    curators_and_admin
  end

  private

  def curators_and_admin
    @user && (
      @user.has_role?(:curator) ||
        @user.has_role?(:admin) ||
        @user.has_role?(:scraper_user))
  end
end
