class EventSerializer < ApplicationSerializer
  attributes :id, :external_id, :title, :subtitle, :url, :organizer, :description,
             :start, :end, :sponsor, :venue, :city, :county, :country, :postcode,
             :latitude, :longitude, :source, :slug, :online, :cost, :for_profit, :last_scraped, :scraper_record,
             :keywords, :event_types, :target_audience, :capacity, :eligibility, :contact, :host_institutions,
             :created_at, :updated_at

  attribute :report, if: -> { policy(object).view_report? }

  def report
    Hash[Event::SENSITIVE_FIELDS.map { |f| [f, object.send(f)] }]
  end

  attribute(:scientific_topics) do
    object.scientific_topics.map do |t|
      { preferred_label: t.preferred_label, uri: t.uri }
    end
  end

  attribute(:external_resources) do
    object.external_resources.map do |er|
      { title: er.title,
        url: er.url,
        created_at: er.created_at,
        updated_at: er.updated_at,
        api_url: er.api_url_of_tool,
        type: er.is_tool? ? 'tool' : 'other' }
    end
  end

  belongs_to :user
  belongs_to :content_provider
  has_many :nodes

end
