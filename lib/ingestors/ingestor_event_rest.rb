require 'ingestors/ingestor_event'
require 'open-uri'
require 'csv'

class IngestorEventRest < IngestorEvent

  def initialize
    super

    @REST_SOURCES = [
      { url: 'https://tess.elixir-europe.org/',
        query: method(:query_elixir),
        process: method(:process_elixir) },
      { url: 'https://www.eventbriteapi.com/v3/',
        query: method(:query_eventbrite),
        process: method(:process_eventbrite) }
    ]

  end

  def read(url)
    begin
      query = nil
      process = nil

      # get the rest source
      @REST_SOURCES.each do |source|
        if url.starts_with? source[:url]
          query = source[:query]
          process = source[:process]
        end
      end

      # abort if no source found for url
      if query.nil? or process.nil?
        raise "REST source not found for URL: #{url}"
      end

      # execute query
      response = query.call url

      # process response
      if response.code == 200
        results = JSON.parse(response.to_str)
        process.call results
      end

    rescue Exception => e
      @messages << "#{self.class.name} failed with: #{e.message}"
    end

    # finished
    return
  end

  def query_eventbrite(url)
    raise 'method not yet implemented'
  end

  def query_elixir(url)
    RestClient::Request.new(method: :get,
                            url: CGI.unescape_html(url),
                            verify_ssl: false,
                            headers: { accept: 'application/vnd.api+json' }).execute
  end

  def process_eventbrite(data)
    raise 'method not yet implemented'
  end

  def process_elixir(results)
    data = results['data']
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
          event.description = convert_description(attr['description'])
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
          @ingested += 1
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end

    # finished
    return
  end
end
