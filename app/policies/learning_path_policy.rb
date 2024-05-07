class LearningPathPolicy < ScrapedResourcePolicy

  def show?
    @record.public? || manage?
  end

  def update?
    super || @record.collaborator?(@user)
  end

  def manage?
    curators_and_admin
  end

  def create?
    curators_and_admin
  end

  class Scope < Scope
    def resolve
      LearningPath.visible_by(@user)
    end
  end

end
