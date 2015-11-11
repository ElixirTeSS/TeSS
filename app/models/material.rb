class Material < ActiveRecord::Base
  include PublicActivity::Common

  has_one :owner, foreign_key: "id", class_name: "User"

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

