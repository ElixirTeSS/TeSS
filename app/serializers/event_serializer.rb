class EventSerializer < ApplicationSerializer
  attributes :id, :external_id, :title, :subtitle, :url, :description,

             :keywords, :event_types, :scientific_topics, :operations, :fields, :external_resources,

             :start, :end, :duration, :timezone,

             :organizer, :sponsors, :contact, :host_institutions,

             :online, :presence, :venue, :city, :county, :country, :postcode, :latitude, :longitude,

             :capacity, :cost_basis, :cost_value, :cost_currency,

             :target_audience, :eligibility, :recognition, :learning_objectives,
             :prerequisites, :tech_requirements,

             :source, :slug, :last_scraped, :scraper_record, :created_at, :updated_at

  attribute :report, if: -> { policy(object).view_report? }

  belongs_to :user
  belongs_to :content_provider
  has_many :nodes
  has_many :collections
  has_many :materials

  def online
    object.online? || object.hybrid?
  end

  def presence
    object.presence.to_s
  end

  def report
    Hash[Event::SENSITIVE_FIELDS.map { |f| [f, object.send(f)] }]
  end

  link(:redirect) { redirect_event_path(object) }
end
