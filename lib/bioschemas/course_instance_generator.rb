module Bioschemas
  class CourseInstanceGenerator < Generator
    def self.type
      'CourseInstance'
    end

    def self.bioschemas_profile
      'https://bioschemas.org/profiles/CourseInstance/1.0-RELEASE'
    end

    property :startDate, :start
    property :endDate, :end
    property :organizer, -> (event) { { '@type' => 'Organization', name: event.organizer } if event.organizer.present? }
    property :location, -> (event) { address(event) },
             condition: -> (event) { event.venue.present? || event.city.present? || event.county.present? ||
               event.country.present? || event.postcode.present? }

    property :funder, -> (event) {
      event.sponsors.map { |sponsor| { '@type' => 'Organization', 'name' => sponsor } }
    }
    property :maximumAttendeeCapacity, :capacity
    property :courseMode, :presence
  end
end
