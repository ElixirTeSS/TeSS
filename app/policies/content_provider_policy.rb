class ContentProviderPolicy < ResourcePolicy

  class Scope < Scope
    def resolve
      ContentProvider.all
    end
  end

end
