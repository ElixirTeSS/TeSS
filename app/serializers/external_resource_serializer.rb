class ExternalResourceSerializer < ApplicationSerializer

  attributes :title, :url, :created_at, :updated_at
  attribute(:api_url) { object.api_url_of_tool }
  attribute(:type) { object.is_tool? ? 'tool' : 'other' }

end
