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
      if user.is_admin?
        Package.all
      else
        query = Package.unscoped.where(public: true, user: user)
        Package.where(query.where_values.inject(:or))
      end
    end
  end

end
