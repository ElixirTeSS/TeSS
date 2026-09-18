class MaterialPolicy < ScrapedResourcePolicy
  def show?
    super && shown?
  end

  def clone?
    curators_and_admin
  end

  def approve?
    curators_and_admin
  end

  private

  def approval_enabled?
    TeSS::Config.feature['material_under_admin_approval']
  end
end