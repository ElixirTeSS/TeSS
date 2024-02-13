module Bioschemas
  class EventGenerator < Generator
    def self.type
      'Event'
    end

    def self.bioschemas_profile
      'https://bioschemas.org/profiles/Event/0.2-DRAFT-2019_06_14'
    end

    property :name, :title
    property :alternateName, :subtitle
    property :url, :url
    property :description, :description
    property :keywords, :keywords
    property :startDate, :start
    property :endDate, :end
    property :organizer, -> (event) { { '@type' => 'Organization', name: event.organizer } if event.organizer.present? }
    property :location, -> (event) { address(event) },
             condition: -> (event) { event.venue.present? || event.city.present? || event.county.present? ||
               event.country.present? || event.postcode.present? }
    property :hostInstitution, :host_institutions
    property :contact, :contact
    property :funder, -> (event) {
      event.sponsors.map { |sponsor| { '@type' => 'Organization', 'name' => sponsor } }
    }
    property :audience, -> (event) {
      event.target_audience.map { |audience| { '@type' => 'Audience', 'audienceType' => audience } }
    }
    property :maximumAttendeeCapacity, :capacity
    property :event_types, :event_types
    property :eligibility, :eligibility
    property :about, -> (event) {
      event.scientific_topics.map { |t| term(t) }
    }
  end
end
