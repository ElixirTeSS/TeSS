class PackageMaterial < ApplicationRecord
  belongs_to :material
  belongs_to :package

  include PublicActivity::Common

  self.primary_key = 'id'

  after_save :log_activity

  def log_activity
    self.package.create_activity(:add_material, owner: User.current_user,
                                 parameters: { material_id: self.material_id, material_title: self.material.title })
    self.material.create_activity(:add_to_package, owner: User.current_user,
                                  parameters: { package_id: self.package_id, package_title: self.package.title })
  end
end
