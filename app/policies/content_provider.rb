class ContentProviderPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      ContentProvider.all
    end
  end
end
