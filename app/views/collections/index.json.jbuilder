# frozen_string_literal: true

json.array!(@collections) do |collection|
  json.extract! collection, :id, :title, :description, :image_url
  json.url collection_url(collection, format: :json)
end
