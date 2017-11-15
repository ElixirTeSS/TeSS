class ContentProviderSerializer < ApplicationSerializer
  attributes :id, :title, :description, :url, :image_url, :keywords, :created_at, :updated_at

  has_many :events
  has_many :materials
end
