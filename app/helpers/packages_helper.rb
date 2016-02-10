module PackagesHelper
  def available_packages_for(material=nil)
    return [] if material.nil?
    if !current_user.nil?
      return current_user.packages - material.packages
    else
      return []
    end
  end
end
