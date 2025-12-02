# frozen_string_literal: true

require 'icalendar'
require 'nokogiri'
require 'open-uri'
require 'tzinfo'

module Ingestors
  # Reads from direct .ics or Indico (event or category) URLs, .xml sitemaps, and .txt sitemaps.
  class IndicoIngestor < Ingestor
    include Ingestors::Concerns::SitemapHelpers

    def self.config
      {
        key: 'indico',
        title: 'Indico / .ics file',
        category: :events
      }
    end

    def read(source_url)
      @token = Rails.application.config.secrets.indico_api_token
      @verbose = false
      sources = get_sources(source_url)
      return if sources.nil?

      sources.each do |url|
        process_url(url)
      end
    end

    private

    # Modifies the given URL to the ics export.
    # Loops into each event to process it.
    # Note: One .ics file can have multiple events.
    def process_url(url)
      export_url = to_export(url)
      raise 'Not an indico link' if export_url.nil?

      content = open_url(export_url, raise: true, token: @token).set_encoding('utf-8')
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
    # This method never mutates the original URL string.
    # Returns the updated URL string or nil if input is blank.
    def to_export(url)
      return nil if url.blank?

      uri = URI.parse(url)
      path = uri.path.to_s

      if path.match?(%r{/(event|events)\.ics\z})
        uri.to_s
      elsif indico_page?(uri)
        ensure_events_ics_path(uri)
      end
    end

    def indico_page?(uri)
      # Either checks in host, e.g., 'indico.myinstitution.com'
      return true if uri.host&.include?('indico')

      # Or checks in meta tags
      html = open_url(uri, raise: true)
      doc = Nokogiri::HTML(html)
      content = doc.at('meta[property="og:site_name"]')&.[]('content')
      content&.match?(/indico/i)
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

    # Builds the OpenStruct event and adds it in event.
    def process_calevent(calevent)
      event_to_add = OpenStruct.new.tap do |event|
        assign_basic_info(event, calevent)
        assign_time_info(event, calevent)
        assign_location_info(event, calevent.location)
      end
      add_event(event_to_add)
    rescue StandardError => e
      @messages << "process_calevent failed with: #{e.message}"
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
