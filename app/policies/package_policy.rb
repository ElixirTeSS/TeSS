class PackagePolicy < ResourcePolicy

  class Scope < Scope
    def resolve
      if user.is_admin?
        Package.all
      else
        query = Package.unscoped.where(public: true, user: user)
        Package.where(query.where_values.inject(:or))
      end
    end
  end

end
