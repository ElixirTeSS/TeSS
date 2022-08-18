base_fields = [:id, :external_id, :title, :subtitle, :url, :organizer, :description, :start, :end, :sponsors, :venue,
               :city, :country, :postcode, :latitude, :longitude, :created_at, :updated_at, :source, :slug,
               :content_provider_id, :user_id, :online, :last_scraped, :scraper_record, :keywords, :event_types,
               :target_audience, :capacity, :eligibility, :contact, :host_institutions, :prerequisites,
               :tech_requirements, :cost_basis, :cost_value ]

json.array!(@events) do |event|
  fields = base_fields
  fields += Event::SENSITIVE_FIELDS if policy(event).view_report?

  json.extract! event, *fields

  json.partial! 'common/ontology_terms', type: 'scientific_topics', resource: event
  json.partial! 'common/ontology_terms', type: 'operations', resource: event

  json.nodes event.associated_nodes.collect { |x| { :name => x[:name], :node_id => x[:id] } }

  json.url

  json.external_resources do
    event.external_resources.each do |external_resource|
      json.partial! 'common/external_resource', external_resource: external_resource
    end
  end

end
