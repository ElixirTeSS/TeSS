# A policy specific to things that have been scraped. Events and Materials

class ScrapedResourcePolicy < ResourcePolicy

  def manage?
    super || (@user && @user.is_curator?)
  end

end
