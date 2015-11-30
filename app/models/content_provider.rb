class ContentProvider < ActiveRecord::Base

  include PublicActivity::Common

  has_many :materials

  unless SOLR_ENABLED==false
    searchable do
      text :title
      text :description
    end
  end
  # TODO: Add validations for these:
  # title:text url:text logo_url:text description:text

  # TODO:
  # Add link to Node, once node is defined.

end
