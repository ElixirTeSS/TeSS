require 'icalendar'
require 'nokogiri'
require 'open-uri'
require 'tzinfo'

module Ingestors
  class IcalIngestor < Ingestor
    include Ingestors::Concerns::SitemapHelpers

    def self.config
      {
        key: 'ical',
        title: 'iCalendar',
        category: :events
      }
    end

    def read(url)
      sources = parse_sitemap(url)
      sources.each do |source|
        process_icalendar(source)
      end
    end

    private

    def process_icalendar(url)
      # process individual ics file
      query = '?ical=true'

      # append query  (if required)
      file_url = url
      file_url << query unless url.to_s.downcase.ends_with? query

      # process file
      data = open_url(file_url)
      if data
        events = Icalendar::Event.parse(data.set_encoding('utf-8'))

        # process each event
        events.each do |ical_event|
          add_event(process_event(ical_event))
        end
      end
      # finished
    end

    def process_event(calevent)
      # set fields
      event = OpenStruct.new
      event.url = calevent.url&.to_s
      event.title = calevent.summary&.to_s
      event.description = process_description(calevent.description)

      event.end = calevent.dtend&.to_time
      unless calevent.dtstart.nil?
        dtstart = calevent.dtstart
        event.start = dtstart&.to_time
        tzid = dtstart.ical_params['tzid']
        event.timezone = tzid.first.to_s if tzid.present?
      end

      if calevent.location
        event.venue = calevent.location.to_s
        if calevent.location.downcase.include?('online')
          event.online = true
          event.city = nil
          event.postcode = nil
          event.country = nil
        end
      end

      event.keywords = calevent.categories.flatten.map(&:strip)

      event
    end

    def process_description(input)
      return input if input.nil?

      convert_description(input.to_s.gsub(/\R/, '<br />'))
    end
  end
end
