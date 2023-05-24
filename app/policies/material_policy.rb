class MaterialPolicy < ScrapedResourcePolicy

  def clone?
    manage?
  end

end