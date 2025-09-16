class LearningPathPolicy < ScrapedResourcePolicy

  def show?
    @record.public? || update? || manage?
  end

  def update?
    super || @record.collaborator?(@user)
  end

  def manage?
    curators_and_admin || user_has_role?(:learning_path_curator)
  end

  def create?
    manage?
  end

  class Scope < Scope
    def resolve
      LearningPath.visible_by(@user)
    end
  end

end
