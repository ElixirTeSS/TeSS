class EventPolicy < ScrapedResourcePolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope unless TeSS::Config.feature['event_under_admin_approval']
      return scope if user&.is_admin? || user&.is_curator?

      approved_scope = scope.approved
      return approved_scope unless user

      user_conditions = scope.where(user_id: user.id)

      if scope.reflect_on_association(:space)
        admin_space_ids = user.space_roles.where(key: 'admin').pluck(:space_id)
        user_conditions = user_conditions.or(scope.where(space_id: admin_space_ids)) if admin_space_ids.any?
      end

      approved_scope.or(user_conditions)
    end
  end

  # Determines whether the record should be visible to the current user,
  # considering space privacy and resource approval status.
  def show?
    super && shown?
  end

  def edit_report?
    manage?
  end

  def view_report?
    manage?
  end

  def clone?
    manage? || curators_and_admin
  end

  # For the edit and clone buttons
  def update?
    manage? || curators_and_admin || user&.has_space_role?(record.space, :admin)
  end

  # For the approve rights
  def approve?
    approval_enabled? && curatable_by_user?
  end

  def request_approval?
    approval_enabled? && curatable_by_user?
  end

  private

  def approval_enabled?
    TeSS::Config.feature['event_under_admin_approval']
  end

  def curatable_by_user?
    return false unless user
    return true if user.is_admin?
    return true if user.has_space_role?(record.space, 'admin')
    return true if user.is_curator? && (record.space.nil? || !record.space.is_private)
    
    false
  end
end
