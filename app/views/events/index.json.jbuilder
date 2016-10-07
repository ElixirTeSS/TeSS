json.array!(@events) do |event|
  json.extract! event, :id, :title, :subtitle, :url, :organizer, :host_institutions, :scientific_topics,
                :description, :event_types, :start, :end, :sponsor, :venue, :city, :county, :country, :postcode,
                :latitude, :longitude, :created_at, :updated_at, :target_audience, :eligibility, :capacity, :contact,
                :keywords, :host_institutions
  json.url event_url(event, format: :json)
end
