class WorkflowPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      if user.is_admin?
        Workflow.all
      else
        query = Workflow.unscoped.where(public: true, owner: user)
        Workflow.where(query.where_values.inject(:or))
      end
    end
  end

end
