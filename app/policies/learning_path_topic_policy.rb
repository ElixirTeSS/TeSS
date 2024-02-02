class LearningPathTopicPolicy < ResourcePolicy

  def update?
    super || @record.collaborator?(@user)
  end

  def manage?
    curators_and_admin
  end

  def create?
    curators_and_admin
  end

end
