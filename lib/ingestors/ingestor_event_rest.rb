require 'ingestors/ingestor_event'
require 'open-uri'
require 'csv'

class IngestorEventRest < IngestorEvent

  def initialize
    super
  end

  def read(url)
    processed = 0

    begin
      # execute query
      response = query_elixir(url)

      if response.code == 200
        # format response
        results = JSON.parse(response.to_str)
        
        # source translations
        processed = process_elixir(results['data'], results['meta'])
      end

    rescue Exception => e
      Scraper.log self.class.name + ': failed with: ' + e.message, 3
    end

    # log processed count
    Scraper.log self.class.name + ': events extracted = ' + processed.to_s, 3

    return processed

  end

  def query_elixir (url)
    RestClient::Request.new(method: :get,
                            url: CGI.unescape_html(url),
                            verify_ssl: false,
                            headers: { accept: 'application/vnd.api+json'} ).execute
  end

  def process_elixir(data, meta)
    processed = 0

    # extract materials from results
    unless data.nil? or data.size < 1
      data.each do |item|
        begin
          # create new event
          event = Event.new

          # extract event details from
          attr = item['attributes']
          event.title = attr['title']
          event.url = attr['url']
          event.description = attr['description']
          event.start = attr['start']
          event.end = attr['end']
          event.timezone = 'UTC'
          event.contact = attr['contact']
          event.organizer = attr['organizer']
          event.online = attr['online']
          event.city = attr['city']
          event.country = attr['country']
          event.venue = attr['venue']
          event.online = true if attr['venue'] == 'Online'

          # array fields
          event.keywords = []
          attr['keywords'].each { |keyword| event.keywords << keyword } unless attr['keywords'].nil?

          event.host_institutions = []
          attr['host-institutions'].each { |host| event.host_institutions << host } unless attr['host-institutions'].nil?

          # dictionary fields
          event.eligibility = []
          unless attr['eligibility'].nil?
            attr['eligibility'].each do |key|
              value = convert_eligibility(key)
              event.eligibility << value unless value.nil?
            end
          end
          event.event_types = []
          unless attr['event_types'].nil?
            attr['event_types'].each do |key|
              value = convert_event_types(key)
              event.event_types << value unless value.nil?
            end
          end

          # add event to events array
          add_event(event)
        rescue Exception => e
          Scraper.log self.class.name + 'Extract event fields failed with: ' + e.message, 4
        end
        processed += 1
      end

    end

    return processed
  end
end
