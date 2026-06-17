class EventPolicy < ScrapedResourcePolicy

  def show?
    shown?
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

end
