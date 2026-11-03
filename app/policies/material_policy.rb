class MaterialPolicy < ScrapedResourcePolicy

  def show?
    super && shown?
  end

  def clone?
    manage?
  end

end