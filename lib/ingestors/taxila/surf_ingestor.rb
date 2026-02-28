require 'open-uri'
require 'csv'
require 'nokogiri'
require 'active_support/core_ext/hash'

module Ingestors
  module Taxila
    class SurfIngestor < Ingestor
      def self.config
        {
          key: 'surf_event',
          title: 'Surf Events API',
          category: :events
        }
      end

      def read(url)
        begin
          process_surf(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_surf(url)
        ical_surf_url = "https://www.surf.nl/ical/surf-agenda.ics"
        ical_events = Icalendar::Event.parse(open_url(ical_surf_url, raise: true).set_encoding('utf-8'))
        events = {}
        ical_events.each do |ical_event|
          title = ical_event.summary.to_s
          events[title] ||= OpenStruct.new
          events[title].title = title
          events[title].url = "https://www.surf.nl/agenda##{title.parameterize(separator: '_')}"
          events[title].description ||= ical_event.description.to_s
          my_start = Time.zone.parse(ical_event.dtstart.strftime('%a, %d %b %Y %H:%M:%S'))
          my_end = Time.zone.parse(ical_event.dtend.strftime('%a, %d %b %Y %H:%M:%S'))
          events[title].start ||= my_start
          events[title].end ||= my_end
          events[title].set_default_times
          events[title].venue ||= ical_event.location
          events[title].source ||= 'SURF'
          events[title].timezone ||= 'Amsterdam'

          events[title].start = [my_start, events[title].start].min
          events[title].end = [my_end, events[title].end].max
        rescue Exception => e
          puts e
          @messages << "Extract event fields failed with: #{e.message}"
        end
        events.values.each do |event|
          add_event(event)
        rescue Exception => e
          puts e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end
