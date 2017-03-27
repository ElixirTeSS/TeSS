json.extract! @package, :id, :title, :description, :image_url, :events, :materials, :created_at, :updated_at

json.events @package.events do |event|
  json.title event.title
  json.url event_url(event)
end

json.materials @package.materials do |material|
  json.title material.title
  json.url material_url(material)
end
