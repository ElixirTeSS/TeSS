require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  module Taxila
    class OdisseiIngestor < Ingestor
      def self.config
        {
          key: 'odissei_event',
          title: 'ODISSEI Events API',
          category: :events
        }
      end

      def read(url)
        begin
          process_odissei(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_odissei(_url)
        odissei_url = 'https://odissei-data.nl/calendar/'

        workshop_title_list = []
        workshop_url_list = []
        event_page = Nokogiri::HTML5.parse(open_url(odissei_url.to_s,
                                                    raise: true)).css('.events.archive > .event')
        event_page.each do |event_section|
          event = OpenStruct.new
          event.title = event_section.css('.event-information > .event-title > a').first.text
          event.url = event_section.css('.event-information > .event-title > a').first.get_attribute('href')
          event.description = event_section.css('.event-teaser > p').first.text
          event.venue = event_section.css('.event-location').first.text || 'unknown'

          year = Time.zone.now.year
          month = event_section.css('.event-day > div > strong').first.text
          day = event_section.css('.event-day-number').first.text
          times = event_section.css('.event-time').first.text.split('-')
          event.start = Time.zone.parse("#{year} #{month} #{day}")
          event.start = event.start.change(year: year + 1) if event.start < Time.zone.now - 2.weeks
          event.end = event.start
          if times.length == 2
            for separator in [':', '.']
              hour, min = times[0].split(separator) if times[0].split(separator).length == 2
              event.start = event.start.change(hour:, min:)
              hour, min = times[1].split(separator) if times[0].split(separator).length == 2
              event.end = event.end.change(hour:, min:)
            end
          end

          event.source = 'ODISSEI'
          event.timezone = 'Amsterdam'
          event.set_default_times
          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end

def odissei_recursive_description_func(css, res = '')
  if css.length == 1
    res += css.text.strip
  else
    css.each do |css2|
      res += recursive_description_func(css2, res)
    end
  end
  res
end
