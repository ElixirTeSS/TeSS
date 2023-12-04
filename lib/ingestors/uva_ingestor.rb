require 'open-uri'
require 'csv'

module Ingestors
  class UvaIngestor < Ingestor
    def self.config
      {
        key: 'uva_event',
        title: 'UvA Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_uva(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_uva(url)
      # execute REST request
      results = get_json_response url
      data = results.to_h['items']

      return if data.nil? || data.empty?

      # extract materials from results
      data.each do |item|
        # create new event
        event = OpenStruct.new

        # extract event details from
        attr = item
        event.title = attr.fetch('title', '')
        event.url = attr.fetch('url', '')&.strip
        event.organizer = attr.fetch('org', '')
        event.description = convert_description attr.fetch('lead', '')
        event.start = attr.fetch('startDate', '')
        event.end = attr.fetch('endDate', '')
        event.set_default_times
        event.venue = attr.fetch('locations', []).first&.fetch('title', '')
        event.city = 'Amsterdam'
        event.country = 'The Netherlands'
        event.source = 'UvA'
        event.online = attr.fetch('online_event', false)
        event.timezone = 'Amsterdam'

        # array fields
        event.keywords = attr.fetch('taxonomy', []).map(&:values).flatten

        event.event_types = attr.fetch('eventType', []).map { |t| convert_event_types(t) }

        # add event to events array
        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
