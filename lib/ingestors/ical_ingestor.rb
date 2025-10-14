# frozen_string_literal: true

require 'icalendar'
require 'nokogiri'
require 'open-uri'
require 'tzinfo'

module Ingestors
  # Reads from direct ical / .ics / Indico (event or category) URLs, .xml sitemaps, and .txt sitemaps.
  class IcalIngestor < Ingestor
    include Ingestors::Concerns::SitemapHelpers
    include Ingestors::Concerns::IcalIngestorExportUrl

    def self.config
      {
        key: 'ical',
        title: 'iCalendar / Indico / .ics File',
        category: :events
      }
    end

    def read(source_url)
      @verbose = false
      sources = get_sources(source_url)
      return if sources.nil?

      sources.each do |url|
        process_url(url)
      end
    end

    private

    # Modifies the given URL to the ics or ical export.
    # Loops into each Ical event to process it.
    # Note: One .ics file can have multiple Ical events.
    def process_url(url)
      export_url = to_export(url)
      events = Icalendar::Event.parse(open_url(export_url, raise: true).set_encoding('utf-8'))
      events.each do |e|
        process_calevent(e)
      end
    rescue StandardError => e
      @messages << "Process file url[#{export_url}] failed with: #{e.message}"
    end

    # Builds the OpenStruct event and adds it in event.
    def process_calevent(calevent)
      event_to_add = OpenStruct.new.tap do |event|
        assign_basic_info(event, calevent)
        assign_time_info(event, calevent)
        assign_location_info(event, calevent.location)
      end
      add_event(event_to_add)
    rescue StandardError => e
      @messages << "Process iCalendar failed with: #{e.message}"
    end

    # Assigns to event: url, title, description, keywords.
    def assign_basic_info(event, calevent)
      event.url = calevent.url.to_s
      event.title = calevent.summary.to_s
      event.description = process_description calevent.description
      event.keywords = process_keywords(calevent.categories)
    end

    # Assigns to event: start, end, timezone.
    def assign_time_info(event, calevent)
      event.start = calevent.dtstart&.to_time unless calevent.dtstart.nil?
      event.end = calevent.dtend&.to_time unless calevent.dtend.nil?
      event.timezone = get_tzid(calevent.dtstart)
    end

    # Assigns to event: venue, online, city.
    def assign_location_info(event, location)
      return if location.blank? || !location.present?

      event.venue = location.to_s
      event.online = location.downcase.include?('online')
      event.city, event.postcode, event.country = process_location(location)
    end

    # Removes all `<br />` tags and converts HTML to MD.
    def process_description(input)
      return input if input.nil?

      desc = input.to_s.gsub('', '<br />')
      convert_description(desc)
    end

    # Extracts the timezone identifier (TZID) from an iCalendar event's dtstart field.
    # Handles whether tzid shows up as an Array or a single string
    def get_tzid(dtstart)
      return nil unless dtstart.respond_to?(:ical_params)

      tzid = dtstart.ical_params['tzid']
      return nil if tzid.nil?

      tzid.is_a?(Array) ? tzid.first.to_s : tzid.to_s
    end

    # Returns an array of 3 location characteristics: suburb, postcode, country
    # Everything is nil if location.blank or location is online
    def process_location(location)
      return [nil, nil, nil] if location.blank?

      if location.to_s.downcase.include?('online')
        [nil, nil, nil]
      else
        [
          location['suburb'],
          location['postcode'],
          location['country']
        ]
      end
    end

    # Returns keywords from the `CATEGORIES` ICal field
    def process_keywords(categories)
      return [] if categories.blank?

      categories.flatten.compact.map { |cat| cat.to_s.strip }
    end
  end
end
