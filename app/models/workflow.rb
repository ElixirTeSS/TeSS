class Workflow < ActiveRecord::Base

  include PublicActivity::Common
  include HasScientificTopics
  include Collaboratable

  has_paper_trail

  extend FriendlyId
  friendly_id :title, use: :slugged

  if SOLR_ENABLED
    searchable do
      string :title
      string :description
      text :title
      text :description
    end
  end

  # has_one :owner, foreign_key: "id", class_name: "User"
  belongs_to :user

  validates :title, presence: true

  clean_array_fields(:keywords, :contributors, :authors, :target_audience)

  update_suggestions(:keywords, :contributors, :authors, :target_audience)

  def self.facet_fields
    %w( )
  end

end
