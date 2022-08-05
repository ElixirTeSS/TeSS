module Bioschemas
  class EventGenerator < Generator
    def self.type
      'Event'
    end

    property :name, :title
    property :alternateName, :subtitle
    property :url, :url
    property :description, :description
    property :keywords, :keywords
    property :startDate, :start
    property :endDate, :end
    property :organizer, -> (event) { { '@type' => 'Organization', name: event.organizer } if event.organizer }
    property :location, -> (event) {
      {
        '@type' => 'PostalAddress',
        'streetAddress' => event.venue,
        'addressLocality' => event.city,
        'addressRegion' => event.county,
        'addressCountry' => event.country,
        'postalCode' => event.postcode
      }.compact
    }, condition: -> (event) { event.venue.present? || event.city.present? || event.county.present? ||
      event.country.present? || event.postcode.present? }
    # property :hostInstitution, :host_institutions # Does not seem to be a valid Schema/Bioschemas property
    # property :contact, :contact
    property :funder, -> (event) {
      event.sponsors.map { |sponsor| { '@type' => 'Organization', 'name' => sponsor } }
    }
    property :audience, -> (event) {
      event.target_audience.map { |audience| { '@type' => 'Audience', 'audienceType' => audience } }
    }
    property :maximumAttendeeCapacity, :capacity
    # property :event_types, event.event_types
    # property :eligibility, event.eligibility
    property :about, -> (event) {
      event.scientific_topics.map { |t| term(t) }
    }
  end
end
