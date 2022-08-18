class MaterialSerializer < ApplicationSerializer
  attributes :id, :title, :url, :description, :doi, :remote_updated_date, :remote_created_date, :keywords, :licence,
             :difficulty_level, :contributors, :authors, :target_audience, :scientific_topics, :operations,
             :external_resources, :created_at, :updated_at

  belongs_to :user
  belongs_to :content_provider
  has_many :nodes
end
