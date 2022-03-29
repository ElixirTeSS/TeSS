require 'ingestors/ingestor_event'
require 'open-uri'
require 'csv'

class IngestorEventRest < IngestorEvent

  def initialize
    super

    @RestSources = [
      { url: 'https://tess.elixir-europe.org/',
        process: method(:process_elixir) },
      { url: 'https://www.eventbriteapi.com/v3/',
        process: method(:process_eventbrite) }
    ]

  end

  def read(url)
    begin
      query = nil
      process = nil

      # get the rest source
      @RestSources.each do |source|
        if url.starts_with? source[:url]
          process = source[:process]
        end
      end

      # abort if no source found for url
      raise "REST source not found for URL: #{url}" if process.nil?

      # process url
      process.call(url)

    rescue Exception => e
      @messages << "#{self.class.name} failed with: #{e.message}"
    end

    # finished
    return
  end

  private

  def process_eventbrite(url)

    raise "method[#{__method__}] not yet implemented"

=begin
    begin
          # get authorization parameters
          user = Rails.application.secrets.eventbrite_api_v3[:user]
          mytoken = Rails.application.secrets.eventbrite_api_v3[:token]
          raise 'missing user token' if mytoken.nil?
          EventbriteSDK.token = mytoken

          # format query
          org_id = url.split('/').last unless url.nil? or url.split('/').empty?
          puts "org_id = #{org_id}"

          # implement query and response processing
          organiser = EventbriteSDK::Organization.retrieve(id: org_id)
          events = organiser.upcoming_events
          puts "events.count = #{events.size}" unless events.nil?
    rescue Exception => e
      @messages << "#{self.class} failed with: #{e.message}"
    end

=end

    # finished
  end

  def process_elixir(url)
    #puts "process[#{__method__.to_s}] for url[#{url}]"
    # execute request
    response = RestClient::Request.new(method: :get,
                                       url: CGI.unescape_html(url),
                                       verify_ssl: false,
                                       headers: { accept: 'application/vnd.api+json' }).execute

    # check response
    raise "invalid response code: #{response.code}" unless response.code == 200
    results = JSON.parse(response.to_str)
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
