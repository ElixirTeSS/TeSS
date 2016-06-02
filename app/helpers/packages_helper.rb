module PackagesHelper

  def available_packages(resource=nil)
    return [] if resource.nil? || current_user.nil? || !resource.respond_to?(:packages)

    # Admin can add a resource to any package, others only to packages they own
    current_packages = (current_user.is_admin?) ? Package.all : current_user.packages
    return current_packages - resource.packages

  end

end
