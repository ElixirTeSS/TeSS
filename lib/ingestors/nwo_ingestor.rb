require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class NwoIngestor < Ingestor
    def self.config
      {
        key: 'nwo_event',
        title: 'NWO Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_nwo(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_nwo(url)
      4.times.each do |i| # always check the first 4 pages, # of pages could be increased if needed
        sleep(1)
        event_page = Nokogiri::HTML5.parse(URI.open("#{url}?page=#{i}")).css(".overviewContent > .listing-cards > li.list-item > a")
        event_page.each do |event_data|
          event = Event.new

          # dates
          event.title = convert_title event_data.css('h3.card__title').text
          event.timezone = 'Amsterdam'
          event.start, event.end = parse_dates(event_data.css('.card__subtitle').text)
          event.set_default_times

          event.keywords = []
          event.description = convert_description event_data.css('.card__intro').inner_html

          event.url = "https://www.nwo.nl#{event_data['href']}"

          event.source = 'NWO'

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
