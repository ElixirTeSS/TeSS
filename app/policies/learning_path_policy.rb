class LearningPathPolicy < ScrapedResourcePolicy

  def manage?
    curators_and_admin
  end

  def create?
    curators_and_admin
  end

end
