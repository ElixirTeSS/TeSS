json.array!(@events) do |event|
  json.extract! event, :id, :external_id,:title, :subtitle, :url, :organizer, :description,
                :start, :end, :sponsor, :venue, :city, :county, :country, :postcode,
                :latitude, :longitude, :created_at, :updated_at, :source, :slug, :content_provider_id,
                :user_id, :online, :cost, :for_profit, :last_scraped, :scraper_record, :keywords,
                :event_types, :target_audience, :capacity, :eligibility, :contact, :host_institutions,
                :scientific_topic_names
  json.url

  json.external_resources do
    event.external_resources.each do |external_resource|
      json.partial! 'common/external_resource', external_resource: external_resource
    end
  end

end
