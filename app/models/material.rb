class Material < ActiveRecord::Base

  has_one :internal_submitters, foreign_key: "user_id", class_name: "User"
  has_one :submitters, foreign_key: "user_id", class_name: "User"
  has_one :authors, foreign_key: "user_id", class_name: "User"
  has_many :contributors, foreign_key: "user_id", class_name: "User"

  # Generated:
  # title:text url:string short_description:string doi:string  remote_updated_date:date remote_created_date:date local_updated_date:date remote_updated_date:date
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

