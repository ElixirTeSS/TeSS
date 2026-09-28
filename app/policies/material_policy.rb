class MaterialPolicy < ScrapedResourcePolicy
  # Determines whether the record should be visible to the current user,
  # considering space privacy and resource approval status.
  def show?
    super && shown?
  end

  def clone?
    manage? || curators_and_admin
  end

  # For the edit and clone buttons
  def update?
    manage? || curators_and_admin || user&.has_space_role?(record.space, :admin)
  end

  # To check if it has approval rights
  def approve?
    approval_enabled? && curatable_by_user?
  end

  def request_approval?
    approval_enabled? && curatable_by_user?
  end

  private

  def approval_enabled?
    TeSS::Config.feature['material_under_admin_approval']
  end

  def curatable_by_user?
    return false unless user
    return true if user.is_admin?
    return true if user.has_space_role?(record.space, 'admin')
    return true if user.is_curator? && (record.space.nil? || !record.space.is_private)
    
    false
  end
end