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

  def write_attribute(attr_name, value)
    attribute_changed(attr_name, read_attribute(attr_name), value)
    super
  end

  private

  def attribute_changed(attr, old_val, new_val)
    if old_val != new_val
      self.create_activity :update_parameter, parameters: {attr: attr, old_val: old_val, new_val: new_val}
      logger.info "Attribute Changed: #{attr} from #{old_val} to #{new_val}"
    end
  end



end
