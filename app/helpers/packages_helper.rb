module PackagesHelper
  def available_packages_for(material=nil)
     return current_user.packages - material.packages
  end
end
