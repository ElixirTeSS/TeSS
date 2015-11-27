class ContentProvider < ActiveRecord::Base

  include PublicActivity::Common

  has_many :materials
  
  # TODO: Add validations for these:
  # title:text url:text logo_url:text description:text

  # TODO:
  # Add link to Node, once node is defined.

end
