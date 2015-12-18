class PackageMaterial < ActiveRecord::Base
  belongs_to :material
  belongs_to :package

  include PublicActivity::Common

  self.primary_key = 'id'

  after_save :log_activity

  def log_activity
    self.package.create_activity :add_material, parameters: {material: self.material, package: self.package }
    self.material.create_activity :add_to_package, parameters: {material: self.material, package: self.package }
  end
end
