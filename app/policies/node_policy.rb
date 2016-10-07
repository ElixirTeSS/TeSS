class NodePolicy < ApplicationPolicy

  def create?
    # Only admin, api_user, curator or node_curator roles can create
    @user.has_role?(:admin) or @user.has_role?(:api_user) or @user.has_role?(:curator) or @user.has_role?(:node_curator)
  end

  def update?
    return true if @user.is_admin?

    if request_is_api?(@request) #is this an API action - allow api_user roles only
      if @user.has_role?(:api_user) #and @user.is_owner?(@record) # check ownership
        return true
      else
        return false
      end
    end

    if @user.has_role?(:curator) or @user.has_role?(:node_curator) or @user.is_owner?(@record)
        return true
    else
      return false
    end
  end

  class Scope < Scope
    def resolve
      Node.all
    end
  end

end
