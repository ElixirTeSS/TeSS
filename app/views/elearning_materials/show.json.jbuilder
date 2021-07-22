json.extract! @material, :id, :title, :url, :description, :doi, :remote_updated_date, :remote_created_date,
              :created_at, :updated_at, :content_provider_id, :keywords, :licence,
              :difficulty_level, :contributors, :authors, :target_audience

json.partial! 'common/ontology_terms', type: 'scientific_topics', resource: @material
json.partial! 'common/ontology_terms', type: 'operations', resource: @material

json.external_resources do
  @material.external_resources.each do |external_resource|
    json.partial! 'common/external_resource', external_resource: external_resource
  end
end

