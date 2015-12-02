class Package < ActiveRecord::Base
	include PublicActivity::Common
  has_paper_trail

  extend FriendlyId
  friendly_id :name, use: :slugged

	has_many :package_materials
  has_many :package_events
	has_many :materials, through: :package_materials
  has_many :events, through: :package_events

	has_one :owner, foreign_key: "id", class_name: "User"

  unless SOLR_ENABLED==false
    searchable do 
      text :name
      text :description
      string :owner do
      	owner.username.to_s if !owner.nil?
      end
    end
  end

end
