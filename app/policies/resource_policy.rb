# A policy for general "resources" in TeSS. This includes things registered by the scraper and things created by users.

class ResourcePolicy < ApplicationPolicy
  def show?
    !@record.from_unverified_or_rejected? || manage?
  end

  def create?
    super && !@user.has_role?(:basic_user)
  end

  def manage?
    super || (@user&.is_owner?(@record) || scraper?)
  end

end
