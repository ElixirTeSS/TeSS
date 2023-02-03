require 'open-uri'
require 'csv'

module Ingestors
  class DtlsIngestor < Ingestor
    def self.config
      {
        key: 'dtls_event',
        title: 'DTLS Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_dtls(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_dtls(url)
      ['courses/', 'events/'].each do |url_suffix|
        docs = Nokogiri::XML(URI.open(url + url_suffix + 'feed')).xpath('//item')
        docs.each do |event_item|
          begin
            event = Event.new
            event.event_types = ['workshops_and_courses']
            event_item.element_children.each do |element|
              case element.name
              when 'title'
                event.title = convert_title element.text
              when 'link'
                # Use GUID field as probably more stable
                # event.url = element.text
              when 'creator'
                # event.creator = element.text
                # no creator field. Not sure needs one
              when 'guid'
                event.url = element.text
              when 'description'
                event.description = convert_description element.text
              when 'location'
                event.venue = element.text
                loc = element.text.split(',')
                event.city = loc.first.strip
                event.country = loc.last.strip
              when 'provider'
                event.organizer = element.text
              when 'startdate', 'courseDate'
                event.start = element.text.to_s.to_time
              when 'enddate', 'courseEndDate'
                event.end = element.text.to_s.to_time
              when 'latitude'
                event.latitude = element.text
              when 'longitude'
                event.longitude = element.text
              when 'pubDate'
                # Not really needed
              else
                # chuck away
              end
            end
          end
          event.set_default_times
          event.source = 'DTL'
          event.timezone = 'Amsterdam'
          add_event(event)
          @ingested += 1
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
          Sentry.capture_exception(e)
        end
      end
    end
  end
end
