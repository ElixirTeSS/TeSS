json.array!(@events) do |event|
  json.extract! event, :id, :id, :title, :subtitle, :url, :provider, :field, :description, :event_type, :start, :end, :sponsor, :venue, :city, :county, :country, :postcode, :latitude, :longitude
  json.url event_url(event, format: :json)
end
