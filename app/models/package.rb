class Package < ActiveRecord::Base
	include PublicActivity::Common
  	has_paper_trail

	has_many :package_materials
  has_many :package_events
	has_many :materials, through: :package_materials
  has_many :events, through: :package_events

	has_one :owner, foreign_key: "id", class_name: "User"

    searchable do 
      text :name
      text :description
      string :owner do
      	owner.username.to_s if !owner.nil?
      end

    end

end
