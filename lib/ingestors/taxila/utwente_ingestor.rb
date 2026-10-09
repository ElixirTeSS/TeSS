require 'csv'

module Ingestors
  module Taxila
    class UtwenteIngestor < Ingestor
      def self.config
        {
          key: 'utwente_event',
          title: 'UTwente Events API',
          category: :events
        }
      end

      # The events page is a client-rendered app that fetches its data from this fixed WebHare
      # JSON-RPC endpoint - it doesn't move when the page URL does. OBJID identifies the events
      # section in UT's CMS; it would only need updating if UT restructures their site again.
      RPC_URL = 'https://www.utwente.nl/wh_services/utwente_base/rpc/GetNEOItems'
      OBJID = 414426
      PAGE_SIZE = 10
      MAX_PAGES = 50 # safety cap in case the API never reports moreitems: false

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
        skip = 0
        MAX_PAGES.times do
          response = get_json_response(RPC_URL, method: :post, referrer: url,
            headers: {
              content_type: :json,
              accept: :json
            },
            payload: {
              id: 1,
              method: 'GetNEOItems',
              params: [OBJID, 'event', '', nil, { skip: skip, archive: false, tag: 0 }]
            }.to_json)

          result = response['result']
          result['items'].each do |item|
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

          break unless result['moreitems']
          skip += PAGE_SIZE
        end
      end
    end
  end
end
