fields = [
  :id, :external_id, :title, :subtitle, :url, :description,

  :content_provider_id, :user_id,

  :keywords, :event_types, :fields,

  :start, :end, :duration, :timezone, :timezone_inferred, :language,

  :organizer, :sponsors, :contact, :host_institutions,

  :venue, :city, :county, :country, :postcode, :latitude, :longitude,

  :capacity, :cost_basis, :cost_value, :cost_currency,

  :target_audience, :eligibility, :recognition, :learning_objectives,
  :prerequisites, :tech_requirements,

  :source, :slug, :last_scraped, :scraper_record, :created_at, :updated_at
]

fields += Event::SENSITIVE_FIELDS if policy(@event).view_report?

json.extract! @event, *fields
# Local time with the offset of the event's time zone, not the stored wall clock time as UTC
json.set! :start, @event.local_iso8601(@event.start)
json.set! :end, @event.local_iso8601(@event.end)
json.online(@event.online? || @event.hybrid?)

json.partial! 'common/ontology_terms', type: 'scientific_topics', resource: @event
json.partial! 'common/ontology_terms', type: 'operations', resource: @event

json.nodes(@event.associated_nodes.collect { |x| { name: x[:name], node_id: x[:id] } })
json.collections(@event.collections.collect { |x| { title: x[:title], id: x[:id] } })
json.materials(@event.materials.collect { |x| { title: x[:title], id: x[:id] } })

json.external_resources do
  @event.external_resources.each do |external_resource|
    json.partial! 'common/external_resource', external_resource: external_resource
  end
end
