class PackageMaterial < ActiveRecord::Base
  belongs_to :material
  belongs_to :package
end
