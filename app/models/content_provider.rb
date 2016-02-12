require 'tess/array_field_cleaner'

class ContentProvider < ActiveRecord::Base

  include PublicActivity::Common

  extend FriendlyId
  friendly_id :title, use: :slugged

  has_many :materials
  has_many :events

  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :description, :url, :image_url, :squish => false

  validates :title, :url, presence: true

  # Validate the URL is in correct format via valid_url gem
  validates :url, :url => true

  clean_array_fields(:keywords)

  unless SOLR_ENABLED==false
    searchable do
      text :title
      text :description
      string :keywords, :multiple => true
    end
  end
  # TODO: Add validations for these:
  # title:text url:text logo_url:text description:text

  # TODO:
  # Add link to Node, once node is defined.

end
