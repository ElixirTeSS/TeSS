# A policy for general "resources" in TeSS. This includes things registered by the scraper and things created by users.

class ResourcePolicy < ApplicationPolicy

  def create?
    super && !@user.has_role?(:basic_user)
  end

  def manage?
    super || (@user && (@user.is_owner?(@record) || (request_is_api?(@request) && @user.has_role?(:scraper_user))))
  end

end
