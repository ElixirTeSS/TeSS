module PackagesHelper

  PACKAGES_INFO = "Packages can be thought of as folders in which users may collect particular training materials or events, from the full catalogue available within TeSS, to address their specific training needs."

  def available_packages(resource=nil)
    return [] if resource.nil? || current_user.nil? || !resource.respond_to?(:packages)

    # Admin can add a resource to any package, others only to packages they own
    (current_user.is_admin?) ? Package.all : current_user.packages
  end

end
