# frozen_string_literal: true

json.extract! @collection, :id, :title, :description, :image_url, :created_at, :updated_at

json.events @collection.events do |event|
  json.title event.title
  json.url event_url(event)
end

json.materials @collection.materials do |material|
  json.title material.title
  json.url material_url(material)
end
