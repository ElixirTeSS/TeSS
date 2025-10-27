# frozen_string_literal: true

require 'icalendar'
require 'nokogiri'
require 'open-uri'
require 'tzinfo'

module Ingestors
  # Reads from direct ical / .ics / Indico (event or category) URLs, .xml sitemaps, and .txt sitemaps.
  class IcalIngestor < Ingestor
    include Ingestors::Concerns::SitemapHelpers

    def self.config
      {
        key: 'ical',
        title: 'iCalendar / Indico / .ics File',
        category: :events
      }
    end

    def read(source_url)
      @token << Rails.application.config.secrets.indico_api_token
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
      content = open_url(export_url, token: @token, raise: true).set_encoding('utf-8')
      events = Icalendar::Event.parse(content)
      raise 'Not found' if events.nil? || events.empty?

      events.each do |e|
        process_calevent(e)
      end
    rescue StandardError => e
      @messages << "Process file url[#{export_url}] failed with: #{e.message}"
    end

    # 1. If the path already ends with '/events.ics', return as-is.
    # 2. If the host includes 'indico', ensures the path ends with '/events.ics'.
    # 3. Otherwise, append '?ical=true' query param if not already present.
    #
    # This method never mutates the original URL string.
    # Returns the updated URL string or nil if input is blank.
    def to_export(url)
      return nil if url.blank?

      uri = URI.parse(url)
      path = uri.path.to_s

      if path.match?(%r{/(event|events)\.ics\z})
        uri.to_s
      elsif uri.host&.include?('indico')
        ensure_events_ics_path(uri)
      else
        ensure_ical_query(uri)
      end
    end

    # Ensures the Indico URL ends with '/events.ics'
    def ensure_events_ics_path(uri)
      paths = uri.path.split('/')
      uri.path = "#{paths[0..2].join('/')}/"
      if paths[1] == 'event'
        uri.path = File.join(uri.path, 'event.ics')
      elsif paths[1] == 'category'
        uri.path = File.join(uri.path, 'events.ics')
      end
      uri.to_s
    end

    # Ensures the URL has '?ical=true' in its query params
    def ensure_ical_query(uri)
      query = URI.decode_www_form(uri.query.to_s).to_h
      query['ical'] = 'true' unless query['ical'] == 'true'
      uri.query = URI.encode_www_form(query)
      uri.to_s
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
      event.description = calevent.description.to_s
      event.keywords = process_keywords(calevent.categories)
      event.contact = calevent.contact.join(', ')
    end

    # Assigns to event: start, end, timezone.
    def assign_time_info(event, calevent)
      event.start = calevent.dtstart&.to_time unless calevent.dtstart.nil?
      event.end = calevent.dtend&.to_time unless calevent.dtend.nil?
      event.timezone = get_tzid(calevent.dtstart)
    end

    # Assigns to event: venue, online, city.
    def assign_location_info(event, location)
      return if location.blank?

      event.venue = location.to_s
      event.online = location.downcase.include?('online')
      event.city, event.postcode, event.country = process_location(location)
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
      return [location['suburb'], location['postcode'], location['country']] if location.is_a?(Array)

      [nil, nil, nil]
    end

    # Returns keywords from the `CATEGORIES` ICal field
    def process_keywords(categories)
      return [] if categories.blank?

      categories.flatten.compact.map { |cat| cat.to_s.strip }
    end
  end
end
