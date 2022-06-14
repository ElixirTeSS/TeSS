json.array!(@materials) do |material|
  json.extract! material, :id, :title, :url, :description, :doi, :remote_updated_date, :remote_created_date
  json.url material_url(material, format: :json)

  json.partial! 'common/ontology_terms', type: 'scientific_topics', resource: material
  json.partial! 'common/ontology_terms', type: 'operations', resource: material

  json.external_resources do
    material.external_resources.each do |external_resource|
      json.partial! 'common/external_resource', external_resource: external_resource
    end
  end

end


