require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  module Taxila
    class RdnlIngestor < Ingestor
      def self.config
        {
          key: 'rdnl_event',
          title: 'RDNL Events API',
          category: :events
        }
      end

      def read(url)
        begin
          process_rdnl(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_rdnl(url)
        url = "https://researchdata.nl/agenda/"
        event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('main > article > .archive__grid > .column > .archive__content > .column')
        event_page.each do |event_data|
          event = OpenStruct.new

          event.url = event_data.css('h2.card__title > a')[0].get_attribute('href')
          event.title = event_data.css('h2.card__title > a')[0].text.strip

          start_str = event_data.css('dl.meta-list > div > dd')[0].text.strip.split('-')
          if start_str[1].include?(':')
            event.start = Time.zone.parse(start_str[0])
            event.end = Time.zone.parse(start_str[0]).beginning_of_day + Time.zone.parse(start_str[1]).seconds_since_midnight.seconds
          else
            event.start = Time.zone.parse(start_str[0])
            event.end = Time.zone.parse(start_str[1])
          end
          event.start = event.start.change(year: event.end.year) if event.start < event.end - 1.year
          event.start = event.start.change(year: event.end.year - 1) if event.start > event.end
          if event.start < Time.zone.now - 2.weeks
            event.start = event.start.change(year: Time.now.year + 1)
            event.end = event.end.change(year: Time.now.year + 1)
          end

          event.description = event_data.css('.card__excerpt > p')[0].text.strip

          event.venue = event_data.css('dl.meta-list > div > dd')[1].text.strip
          event.source = 'RDNL'
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
