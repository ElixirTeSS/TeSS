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
      if @user.has_role?(:api_user) or @user.is_owner?(@record) # check ownership
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
      # Workflow.unscoped.joins(:collaborations).where('"workflows"."user_id" = :user OR "collaborations"."user_id" = :user', user: user)
      Workflow.all
    end
  end

end
