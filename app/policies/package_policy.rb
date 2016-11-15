class PackagePolicy < ResourcePolicy

  def show?
    @record.public? || manage?
  end

  class Scope < Scope
    def resolve
      Package.visible_by(@user)
    end
  end

end
