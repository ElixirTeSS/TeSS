class EventSerializer < ApplicationSerializer
  attributes :id, :external_id, :title, :subtitle, :url, :organizer, :description, :start, :end, :sponsors, :venue,
             :city, :country, :postcode, :latitude, :longitude, :source, :slug, :online, :last_scraped, :scraper_record,
             :keywords, :event_types, :target_audience, :capacity, :eligibility, :contact, :host_institutions,
             :scientific_topics, :operations, :external_resources, :created_at, :updated_at, :cost_basis, :cost_value

  attribute :report, if: -> { policy(object).view_report? }

  belongs_to :user
  belongs_to :content_provider
  has_many :nodes

  def report
    Hash[Event::SENSITIVE_FIELDS.map { |f| [f, object.send(f)] }]
  end

  def _links
    super.tap do |hash|
      hash[:redirect] = redirect_event_path(object)
    end
  end
end
