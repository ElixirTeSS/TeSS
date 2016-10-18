class WorkflowPolicy < ResourcePolicy

  def update?
    super || @record.collaborator?(@user)
  end

end
