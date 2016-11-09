class PackagePolicy < ResourcePolicy

  def show?
    @record.public? || manage?
  end

  class Scope < Scope
    def resolve
      if @user && @user.is_admin?
        Package.all
      elsif @user
        Package.where('packages.public = ? OR packages.user_id = ?', true, @user)
      else
        Package.where(public: true)
      end
    end
  end

end
