require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  module Taxila
    class UhasseltIngestor < Ingestor
      def self.config
        {
          key: 'uhasselt_event',
          title: 'UHasselt Events API',
          category: :events
        }
      end

      def read(url)
        begin
          process_uhasselt(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_uhasselt(url)
        uhasselt_url = 'https://www.uhasselt.be/en/university-library/research/research-data-management/training-calendar-rdm'
        overview_page = Nokogiri::HTML5.parse(open_url(uhasselt_url.to_s, raise: true)).css("table").first.css('tr')
        overview_page.each_with_index do |el, idx|
          if el.css('td').length != 4
            next
          end

          new_url = "https://www.uhasselt.be#{el.css('td').last.css('a').first.get_attribute('href').to_s}"
          sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/uhasselt.yml')
          event_page = Nokogiri::HTML5.parse(open_url(new_url.to_s, raise: true))

          event = OpenStruct.new
          event.url = new_url.to_s
          event.title = event_page.css('.uhasselt-container > .column > div > h1.heading').first.text.strip
          time_strs = event_page.css('.uhasselt-container > .column > .extra-agenda-info > .info-row').first.text.strip.split('-')
          event.start = DateTime.parse(time_strs[0].strip)
          if time_strs.length > 1
            event.end = DateTime.parse(time_strs[1].strip)
          end
          event.set_default_times
          event.description = event_page.css('.uhasselt-container > h2#anch-content').first.parent.css('.paragraph').first.text.strip
          event.venue = event_page.css('.uhasselt-container > .column > .extra-agenda-info > .info-row').last.text.strip
          
          event.source = 'UHasselt'
          event.timezone = 'Amsterdam'

          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end
