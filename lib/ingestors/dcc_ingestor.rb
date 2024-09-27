require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class DccIngestor < Ingestor
    def self.config
      {
        key: 'dcc_event',
        title: 'DCC Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_dcc(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_dcc(url)
      # event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('main > .archive__content.grid > .column.span-4-sm.span-4-md.span-6-lg')
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('main > article > .archive__grid > .column > .archive__content > .column')
      event_page.each do |event_data|
        event = OpenStruct.new

        event.url = event_data.css('h2.post-item__title > a')[0].get_attribute('href')
        event.title = event_data.css('h2.post-item__title > a')[0].text.strip

        start_str = event_data.css('ul.post-item__meta > li')[0].text.strip.split('—')
        if start_str[1].include?(':')
          event.start = Time.zone.parse(start_str[0])
          event.end = Time.zone.parse(start_str[0]).beginning_of_day + Time.zone.parse(start_str[1]).seconds_since_midnight.seconds
        else
          event.start = Time.zone.parse(start_str[0])
          event.end = Time.zone.parse(start_str[1])
        end

        event.venue = event_data.css('ul.post-item__meta > li')[1].text.strip

        event.source = 'DCC'
        event.timezone = 'Amsterdam'
        event.set_default_times

        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
