class ContentProviderSerializer < ApplicationSerializer
  attributes :id, :slug, :title, :description, :url, :image_url, :keywords, :created_at, :updated_at, :contact,
             :scraper_record, :last_scraped

  has_many :events
  has_many :materials
end
