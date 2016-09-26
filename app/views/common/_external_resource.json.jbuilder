json.extract! external_resource, :title, :url, :created_at, :updated_at
json.api_url external_resource.api_url_of_tool
json.type external_resource.is_tool? ? 'tool' : 'other'