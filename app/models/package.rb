require 'tess/array_field_cleaner'
require 'tess/autocomplete_manager'

class Package < ActiveRecord::Base
	include PublicActivity::Common
  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

	has_many :package_materials
  has_many :package_events
	has_many :materials, through: :package_materials
  has_many :events, through: :package_events

	#has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :image_url, :squish => false

  validates :title, presence: true

  clean_array_fields(:keywords)
  update_suggestions(:keywords)

  after_save :log_activities

  unless SOLR_ENABLED==false
    searchable do 
      text :title
      text :description
      string :user do
      	self.user.username.to_s unless self.user.blank?
      end
      string :keywords, :multiple => true
      
      string :user, :multiple => true do
        if self.user
          if self.user.profile and (self.user.profile.firstname or self.user.profile.surname)
            "#{self.user.profile.firstname} #{self.user.profile.surname}"
          else
            self.user.username
          end
        end
        end
      end
  end
  
  def log_activities
    self.changed.each do |changed_attribute|
      #TODO: Sort out what gets logged
      # If content provider - find content provider otherwise uses ID.
      #     maybe add new activity for content provider having a new material added to it too.
      # If updated at - ignore
      self.create_activity :update_parameter, parameters: {attr: changed_attribute, new_val: self.send(changed_attribute)}
    end
  end
end
