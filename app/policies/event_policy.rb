class EventPolicy < ScrapedResourcePolicy

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
