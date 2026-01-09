class ContentProviderPolicy < ScrapedResourcePolicy
  def create_source?
    (TeSS::Config.feature['user_source_creation'] && manage?) ||
      user_has_role?(:admin, :curator)
  end
end
