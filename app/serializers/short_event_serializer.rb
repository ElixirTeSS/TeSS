class ShortEventSerializer < ActiveModel::Serializer
  attributes :id, :external_id, :title, :subtitle, :url, :organizer, :description,
             :start, :end, :sponsor, :venue, :city, :county, :country, :postcode,
             :latitude, :longitude, :source, :slug, :online, :cost, :for_profit, :last_scraped, :scraper_record,
             :keywords, :event_types, :target_audience, :capacity, :eligibility, :contact, :host_institutions,
             :created_at, :updated_at

  belongs_to :user
  belongs_to :content_provider

end
