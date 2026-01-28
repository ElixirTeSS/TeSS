require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  module Taxila
    class OscdIngestor < Ingestor
      def self.config
        {
          key: 'oscd_event',
          title: 'OSCD Events API',
          category: :events
        }
      end

      def read(url)
        begin
          process_oscd(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_oscd(url)
        # url = 'https://osc-delft.github.io/events'
        # url = 'https://osceindhoven.github.io/events'

        event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('.article-post').children
        first_event = true
        event = nil
        event_page.each do |div|
          if div.name == 'h1'
            first_event = false
            event = OpenStruct.new
            event.title = div.text
            event.url = "#{url}##{event.title.downcase.gsub(' ', '_')}"
            event.description = ''
            event.source = 'OSCD'
            event.timezone = 'Amsterdam'
          end

          next if first_event || div.name == 'text'

          if div.name == 'p'
            if div.text.strip.start_with?('Date & time:')
              date_str = div.text.remove('Date & time:').strip
              event.start, event.end = oscd_fix_time(date_str)
            elsif div.text.strip.start_with?('Location:')
              event.venue = div.text.remove('Location:').strip
            else
              event.description = [event.description, div.text.strip].join(' ')
            end
            if div&.next_sibling&.next_sibling.nil? || (div&.next_sibling&.next_sibling&.name == 'h1')
              event.set_default_times
              event.target_audience = parse_audience(event.description)
              add_event(event)
            end
          end
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end

      def oscd_fix_time(date_str)
        date_str.split(',').each do |str|
          str.strip.split(' ').each_cons(2) do |el1, el2|
            next unless is_month?(el1) && el2.to_i.positive?

            event_start = Time.zone.parse([el1, el2].join(' '))
            event_end = Time.zone.parse([el1, el2].join(' '))
            if event_start < (Time.zone.now - 2.weeks)
              event_start = event_start.change(year: event_start.year + 1)
              event_end = event_end.change(year: event_start.year + 1)
            end
            return event_start, event_end
          end
        end
      end

      def is_month?(str)
        formatted_str = str.strip.capitalize
        Date::MONTHNAMES.include?(formatted_str) || Date::ABBR_MONTHNAMES.include?(formatted_str)
      end
    end
  end
end
