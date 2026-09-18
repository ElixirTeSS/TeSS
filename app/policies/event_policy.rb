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
    curators_and_admin
  end

  def approve?
    curators_and_admin
  end

  private

  def approval_enabled?
    TeSS::Config.feature['event_under_admin_approval']
  end
end
