require 'icalendar'
require 'open-uri'
require 'csv'
require 'nokogiri'
require 'openssl'

module Ingestors
  module Taxila
    class OscmIngestor < Ingestor
      def self.config
        {
          key: 'oscm_event',
          title: 'OSCM Events API',
          category: :events,
          ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
        }
      end

      def read(url)
        begin
          process_oscm(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_oscm(url)
        # Instead of using the sitemap we use the events page.
        # The sitemap shows also past events, but the ical link for those does not work, so we can't parse them with the below code.
        url = 'https://www.openscience-maastricht.nl/events/'
        Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('.eventname > a').each do |event_link|
          begin
            event_url = event_link.attributes['href']
            event_page = Nokogiri::HTML5.parse(open_url(event_url, raise: true))

            # create new event
            event = OpenStruct.new

            # extract event details from ical
            ical_event = Icalendar::Event.parse(open_url("#{event_url}/ical/", raise: true).set_encoding('utf-8')).first
            event.title = ical_event.summary
            event.description = convert_description ical_event.description
            event.url = ical_event.url
            # TeSS timezone handling is a bit special.
            event.start = Time.zone.parse(ical_event.dtstart.strftime('%a, %d %b %Y %H:%M:%S'))
            event.end = Time.zone.parse(ical_event.dtend.strftime('%a, %d %b %Y %H:%M:%S'))
            event.set_default_times
            event.venue = ical_event.try(:venue)
            event.keywords = ical_event.categories # fair-coffee pre-registration-workshop fair-essentials-workshop fair-for-qualitative-data reproducibilitea
            # see https://www.openscience-maastricht.nl/wp-sitemap-taxonomies-event-categories-1.xml 
            event.timezone = 'Europe/Amsterdam' # how to get this from Icalendar Event object?
            # it's not really needed since dtstart and dtend contain timezone information
            event.source = 'OSCM'
            event.online = true

            # add event to events array
            add_event(event)
            unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/oscm.yml')
              sleep(1)
            end
          rescue Exception => e
            @messages << "Extract event fields failed with: #{e.message} for #{event_url}"
          end
        end
      end
    end
  end
end
