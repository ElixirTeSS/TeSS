class Workflow < ActiveRecord::Base
  include PublicActivity::Common
  has_paper_trail

  unless SOLR_ENABLED==false
    searchable do
      text :title
      text :description
    end
  end

  has_one :owner, foreign_key: "id", class_name: "User"
end
