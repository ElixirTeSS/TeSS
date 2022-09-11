class WorkflowPolicy < ResourcePolicy

  def update?
    super || @record.collaborator?(@user)
  end

  def show?
    @record.public? || manage?
  end

  class Scope < Scope
    def resolve
      Workflow.visible_by(@user)
    end
  end

end
