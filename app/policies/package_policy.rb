class PackagePolicy < ResourcePolicy

  def initialize(context, record)
    @user = context.user
    @request = context.request
    @record = record
  end

  def show?
    @record.public? || (@user && @user.is_owner?(@record))
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
