module Bioschemas
  class CourseInstanceGenerator < Generator
    def self.type
      'CourseInstance'
    end

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
        'postalCode' => event.postcode,
        'latitude' => event.latitude,
        'longitude' => event.longitude
      }.compact
    }, condition: -> (event) { event.venue.present? || event.city.present? || event.county.present? ||
      event.country.present? || event.postcode.present? }

    property :funder, -> (event) {
      event.sponsors.map { |sponsor| { '@type' => 'Organization', 'name' => sponsor } }
    }
    property :maximumAttendeeCapacity, :capacity
  end
end
