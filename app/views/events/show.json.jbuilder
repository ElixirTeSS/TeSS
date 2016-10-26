json.extract! @event, :id, :title, :subtitle, :url, :organizer, :host_institutions, :scientific_topics,
              :description, :event_types, :start, :end, :sponsor, :venue, :city, :county, :country, :postcode,
              :latitude, :longitude, :created_at, :updated_at, :target_audience, :eligibility, :capacity, :contact,
              :keywords, :host_institutions

json.external_resources do
  @event.external_resources.each do |external_resource|
    json.partial! 'common/external_resource', external_resource: external_resource
  end
end
