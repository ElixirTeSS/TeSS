base_fields = [:id, :external_id,:title, :subtitle, :url, :organizer, :description,
          :start, :end, :sponsor, :venue, :city, :county, :country, :postcode,
          :latitude, :longitude, :created_at, :updated_at, :source, :slug, :content_provider_id,
          :user_id, :online, :cost, :for_profit, :last_scraped, :scraper_record, :keywords,
          :event_types, :target_audience, :capacity, :eligibility, :contact, :host_institutions]

json.array!(@events) do |event|
  fields = base_fields
  if user_signed_in? && policy(current_user, @event).view_report?
    fields += Event::SENSITIVE_FIELDS
  end

  json.extract! event, *fields

  json.partial! 'common/scientific_topics', resource: event

  json.nodes event.associated_nodes.collect{|x| {:name => x[:name], :node_id => x[:id] } }
  
  json.url

  json.external_resources do
    event.external_resources.each do |external_resource|
      json.partial! 'common/external_resource', external_resource: external_resource
    end
  end

end
