class EventPolicy < ScrapedResourcePolicy

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
    manage?
  end

  def approve?
    user_has_role?(:admin)
  end

  def request_approval?
    approval_enabled? && manage?
  end

  private

  def approval_enabled?
    TeSS::Config.feature['event_under_admin_approval']
  end
end
