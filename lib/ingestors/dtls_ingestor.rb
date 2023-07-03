require 'open-uri'
require 'csv'
require 'nokogiri'

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
        docs = Nokogiri::XML(open_url(url + url_suffix + 'feed', raise: true)).xpath('//item')
        docs.each do |event_item|
          begin
            event = OpenStruct.new
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
                event.start = Time.zone.parse(element.text.to_s)
              when 'enddate', 'courseEndDate'
                event.end = Time.zone.parse(element.text.to_s)
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
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end
