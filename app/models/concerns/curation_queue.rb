module CurationQueue
  extend ActiveSupport::Concern

  included do
    after_create :notify_curators, if: :user_requires_approval?
  end

  class_methods do
    def from_verified_users
      joins(:user).where.not(users: { id: User.with_role('unverified_user', Role.rejected.name).pluck(:id) })
    end
  end

  def user_requires_approval?
    user && user.has_role?('unverified_user') && (user.created_resources - [self]).none?
  end

  def notify_curators
    CurationMailer.user_requires_approval(self.user).deliver_later
  end
end
