class MaterialPolicy < ScrapedResourcePolicy

  def show?
    shown?
  end

  def clone?
    manage?
  end

end