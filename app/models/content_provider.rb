class ContentProvider < ActiveRecord::Base

  include PublicActivity::Common
  include LogParameterChanges

  extend FriendlyId
  friendly_id :title, use: :slugged

  has_many :materials, :dependent => :destroy
  has_many :events, :dependent => :destroy

  belongs_to :user
  belongs_to :node

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :url, :image_url, :squish => false

  validates :title, :url, presence: true

  # Validate the URL is in correct format via valid_url gem
  validates :url, :url => true

  clean_array_fields(:keywords)

  PROVIDER_TYPE = ['Organisation', 'Portal', 'Project']#, 'Individual']
  has_image(placeholder: "/assets/placeholder-organization.png")

  if SOLR_ENABLED
    searchable do
      text :title
      string :title
      string :sort_title do
        title.downcase.gsub(/^(an?|the) /, '')
      end
      text :description
      string :keywords, :multiple => true
      string :node, :multiple => true do
        unless self.node.blank?
          self.node.name
        end
      end
      text :node do
        unless self.node.blank?
          self.node.name
        end
      end
      string :content_provider_type
      integer :count do
        if self.events.count > self.materials.count
          self.events.count
        else
          self.materials.count
        end
      end
    end
  end

  # TODO: Add validations for these:
  # title:text url:text image_url:text description:text

  # TODO:
  # Add link to Node, once node is defined.

  def self.facet_fields
    %w( keywords node content_provider_type)
  end

end
