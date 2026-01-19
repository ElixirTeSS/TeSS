class MaterialPolicy < ScrapedResourcePolicy
  def show?
    (super && shown?) || user_management? || administration? || approval_status_approved?
  end

  def clone?
    manage?
  end

  def show?
    user_management? || administration? || approval_status_approved?
  end

  alias_method :orig_manage?, :manage?
  def manage?
    user_management? || administration?
  end

  def index?
    administration?
  end

  def create?
    if TeSS::Config.feature['material_under_admin_approval']
      super
    else
      administration?
    end
  end

  def approve?
    user_has_role?(:admin)
  end

  def request_approval?
    user_management?
  end

  private

  def administration? # Can edit material
    curators_and_admin
  end

  def user_management?
    if TeSS::Config.feature['material_under_admin_approval']
      orig_manage?
    else
      false
    end
  end

  def approval_status_approved?
    TeSS::Config.feature['material_under_admin_approval'] && @record.approved?
  end
end
