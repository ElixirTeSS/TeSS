class NodePolicy < ApplicationPolicy

  def create?
    # Only admin, scraper_user, curator or node_curator roles can create
    @user && (@user.has_role?(:admin) || @user.has_role?(:scraper_user) || @user.has_role?(:curator) || @user.has_role?(:node_curator))
  end

  def manage?
    return false unless @user
    return true if @user.is_admin?

    if request_is_api?(@request) #is this an API action - allow scraper_user roles only
      if @user.has_role?(:scraper_user) #and @user.is_owner?(@record) # check ownership
        return true
      else
        return false
      end
    end

    if @user.has_role?(:curator) || @user.has_role?(:node_curator) || @user.is_owner?(@record)
      return true
    else
      return false
    end
  end

end
