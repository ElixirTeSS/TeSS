require 'open-uri'
require 'csv'

module Ingestors
  class UtwenteIngestor < Ingestor
    def self.config
      {
        key: 'utwente_event',
        title: 'UTwente Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_utwente(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_utwente(url)
      response = get_json_response(url, method: :post, referrer: url,
        headers: {
          content_type: :json,
          accept: :json
        },
        payload: {
          id: 1,
          method: 'GetItems',
          # there may be an issue with multiple categories here...
          params: [{ categories: url.split('=').last }]
        }.to_json)
      
      response['result']['items'].each do |item|
        event = OpenStruct.new

        event.title = item['title']
        event.url = item['link']
        event.start, event.end = parse_dates(item['dateformatted'])
        event.set_default_times
        event.venue = item['location']

        event.keywords = item['tags'].map{ |t| t['tag'] }
        event.description = convert_description item['description']
        event.timezone = 'Amsterdam'
        event.organizer = 'University of Twente'
        event.source = 'University of Twente'
        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
