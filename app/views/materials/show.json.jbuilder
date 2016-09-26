json.extract! @material, :id, :title, :url, :short_description, :doi, :remote_updated_date, :remote_created_date,
              :created_at, :updated_at, :package_ids, :content_provider_id, :keywords, :scientific_topics, :licence,
              :difficulty_level, :contributors, :authors, :target_audience
json.external_resources do
  @material.external_resources.each do |external_resource|
    json.partial! 'common/external_resource', external_resource: external_resource
  end
end

