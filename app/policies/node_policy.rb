class NodePolicy < ApplicationPolicy

  def create?
    # Only admin, scraper_user, curator or node_curator roles can create
    user_has_role?(:admin, :curator, :node_curator) || scraper?
  end

  def manage?
    user_has_role?(:admin, :curator, :node_curator) || scraper? || @user&.is_owner?(@record)
  end

end
