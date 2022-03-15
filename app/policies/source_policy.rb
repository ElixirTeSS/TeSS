class SourcePolicy < ScrapedResourcePolicy

  def new?
    @user && (@user.has_role?(:curator) || @user.has_role?(:admin))
  end

end
