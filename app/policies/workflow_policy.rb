class WorkflowPolicy < ResourcePolicy

  def update?
    super || @record.collaborator?(@user)
  end

  def show?
    @record.public? || manage?
  end

end
