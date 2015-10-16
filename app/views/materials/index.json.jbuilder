json.array!(@materials) do |material|
  json.extract! material, :id, :title, :url, :short_description, :doi, :remote_updated_date, :remote_created_date
  json.url material_url(material, format: :json)
end
