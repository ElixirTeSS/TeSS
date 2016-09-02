class WorkflowPolicy < ApplicationPolicy

  def update?
    manage? || @record.collaborator?(@user)
  end

  def edit?
    update?
  end

  def destroy?
    manage?
  end

  def manage?
    # Admin role can update/destroy any object, other roles can only update objects they created
    return true if @user.is_admin? # allow admin roles for all requests - UI and API
    if request_is_api?(@request) #is this an API action - allow api_user roles only
      if @user.has_role?(:api_user) and @user.is_owner?(@record) # check ownership
        return true
      else
        return false
      end
    end
    if @user.is_owner?(@record) # check ownership
      return true
    else
      return false
    end
  end

  class Scope < Scope
    def resolve
      if user.is_admin?
        Workflow.all
      else
        # For how to do OR queries in Rails 4 see
        # https://coderwall.com/p/dgv7ag/or-queries-with-arrays-as-arguments-in-rails-4
        query = Workflow.unscoped.where(public: true, user: (@workflow.collaborators + [user]))
        Workflow.where(query.where_values.inject(:or))
      end
    end
  end

end
