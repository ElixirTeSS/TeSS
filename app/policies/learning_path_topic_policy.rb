class LearningPathTopicPolicy < ResourcePolicy

  def update?
    super || @record.collaborator?(@user)
  end

  def manage?
    curators_and_admin || user_has_role?(:learning_path_curator)
  end

  def create?
    manage?
  end

end
