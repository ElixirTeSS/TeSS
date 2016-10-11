class ContentProviderPolicy < ScrapedResourcePolicy

  class Scope < Scope
    def resolve
      ContentProvider.all
    end
  end

end
