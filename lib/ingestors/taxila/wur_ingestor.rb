require 'csv'
require 'nokogiri'
require 'json'

module Ingestors
  module Taxila
    class WurIngestor < Ingestor
      def self.config
        {
          key: 'wur_event',
          title: 'WUR Events API',
          category: :events
        }
      end

      def read(url)
        begin
          process_wur(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_wur(_url)
        url = 'https://www.wur.nl/en/news-insights/activities-at-wur'
        html = open_url(url, raise: true).read

        extract_activities(html).each do |activity|
          event = OpenStruct.new
          event.title = activity['title']
          event.url = "https://www.wur.nl#{activity['path']}"
          event.description = activity['summary']
          event.event_types = ['workshops_and_courses']

          location = activity['filterCriteria']&.find { |f| f['label'] == 'Location' }
          event.venue = location && location['value']

          event.start = Time.zone.parse(activity['date']) if activity['date']
          event.end = activity['endDate'] ? Time.zone.parse(activity['endDate']) : event.start
          event.set_default_times

          event.source = 'WUR'
          event.timezone = 'Amsterdam'

          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end

      def extract_activities(html)
        chunks = html.scan(/self\.__next_f\.push\(\[1,"(.*?)"\]\)/m).flatten
        payload = chunks.map { |chunk| JSON.parse("\"#{chunk}\"") }.join

        activities = []
        payload.to_enum(:scan, /\{"id":\d+,"title":"[^"]*"/).each do
          match = Regexp.last_match
          object_str = extract_balanced_json(payload, match.begin(0))
          next unless object_str

          begin
            object = JSON.parse(object_str)
          rescue JSON::ParserError
            next
          end
          activities << object if object['path']&.include?('/activity/')
        end
        activities
      end

      # Pulls out the JSON object starting at `start`, tracking brace depth
      # so that nested objects (filterCriteria, gtm, headerMedia, ...) don't
      # cause it to stop early.
      def extract_balanced_json(str, start)
        depth = 0
        in_string = false
        escaped = false
        i = start
        while i < str.length
          char = str[i]
          if in_string
            if escaped
              escaped = false
            elsif char == '\\'
              escaped = true
            elsif char == '"'
              in_string = false
            end
          else
            case char
            when '"' then in_string = true
            when '{' then depth += 1
            when '}'
              depth -= 1
              return str[start..i] if depth.zero?
            end
          end
          i += 1
        end
        nil
      end
    end
  end
end
