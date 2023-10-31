json.extract! @material, :id, :title, :url, :description,

              :content_provider_id, :user_id,

              :keywords, :resource_type, :other_types, :fields,

              :doi, :licence, :version, :status,

              :contact, :contributors, :authors,

              :difficulty_level, :target_audience, :prerequisites, :syllabus, :learning_objectives, :subsets,

              :date_created, :date_modified, :date_published, :remote_updated_date, :remote_created_date,

              :slug, :last_scraped, :scraper_record, :created_at, :updated_at

json.partial! 'common/ontology_terms', type: 'scientific_topics', resource: @material
json.partial! 'common/ontology_terms', type: 'operations', resource: @material

json.nodes @material.associated_nodes.collect { |x| { name: x[:name], node_id: x[:id] } }
json.collections @material.collections.collect { |x| { title: x[:title], id: x[:id] } }
json.events @material.events.collect { |x| { title: x[:title], id: x[:id] } }

json.external_resources do
  @material.external_resources.each do |external_resource|
    json.partial! 'common/external_resource', external_resource: external_resource
  end
end
