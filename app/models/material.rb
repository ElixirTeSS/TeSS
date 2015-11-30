class Material < ActiveRecord::Base
  include PublicActivity::Common
  has_paper_trail

  unless SOLR_ENABLED==false
    searchable do
      text :title
      text :long_description
      text :short_description
      text :doi
      string :authors, :multiple => true
      string :scientific_topic, :multiple => true
      string :target_audience, :multiple => true
      string :keywords, :multiple => true
      string :licence, :multiple => true
      string :difficulty_level, :multiple => true
      string :contributors, :multiple => true
    end
  end

  has_one :owner, foreign_key: "id", class_name: "User"

  has_many :package_materials
  has_many :packages, through: :package_materials

  belongs_to :content_provider
  # Remove trailing and squeezes (:squish option) white spaces inside the string (before_validation):
  # e.g. "James     Bond  " => "James Bond"
  auto_strip_attributes :title, :short_description, :url, :squish => false

  validates :title, :short_description, :url, presence: true

  # Validate the URL is in correct format via valid_url gem
  validates :url, :url => true

  # Generated:
  # title:text url:string short_description:string doi:string  remote_updated_date:date remote_created_date:date
  # TODO:
=begin
  License
  Scientific topic
  Target audience
  Keywords
  Level
  Duration
  Rating: average score
  Rating: votes
  Rating: reviews
  # Separate models needed for Rating, License, Keywords &c.
=end

end

