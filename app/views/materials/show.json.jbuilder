json.extract! @material, :id, :title, :url, :description, :doi, :licence, :contact, :keywords,
              :remote_updated_date, :remote_created_date, :created_at, :updated_at, :content_provider_id,
              :target_audience, :authors, :contributors, :subsets, :resource_type, :other_types, :version, :status,
              :date_created, :date_modified, :date_published, :prerequisites, :syllabus, :learning_objectives,
              :fields

json.partial! 'common/ontology_terms', type: 'scientific_topics', resource: @material
json.partial! 'common/ontology_terms', type: 'operations', resource: @material

json.external_resources do
  @material.external_resources.each do |external_resource|
    json.partial! 'common/external_resource', external_resource: external_resource
  end
end
