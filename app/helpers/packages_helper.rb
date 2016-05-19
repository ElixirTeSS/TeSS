module PackagesHelper
  def available_packages_for_material(material=nil)
    return [] if material.nil?
    if !current_user.nil?
      return current_user.packages - material.packages
    else
      return []
    end
  end

  def available_packages_for_event(event=nil)
    return [] if event.nil?
    if !current_user.nil?
      return current_user.packages - event.packages
    else
      return []
    end
  end

end
