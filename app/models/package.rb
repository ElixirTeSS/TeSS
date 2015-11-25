class Package < ActiveRecord::Base
	has_many :package_materials
	has_many :materials, through: :package_materials
end
