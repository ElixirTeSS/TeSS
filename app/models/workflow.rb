class Workflow < ActiveRecord::Base
  include PublicActivity::Common
  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  if SOLR_ENABLED==true
    searchable do
      text :title
      text :description
    end
  end

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user

end
