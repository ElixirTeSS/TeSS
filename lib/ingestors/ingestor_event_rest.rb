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

  def read(url, token)
    begin
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
      process.call(url, token)

    rescue Exception => e
      @messages << "#{self.class.name} failed with: #{e.message}"
    end

    # finished
    return
  end

  private

  def process_eventbrite(url, token)
    puts "process_eventbrite: url[#{url}] token[#{token}]"
    begin
      # initialise next_page
      next_page = "#{url}/events/?token=#{token}"

      while next_page
        # execute REST request
        results = get_JSON_response next_page

        # check next page
        pagination = results[:pagination]
        next_page = nil
        begin
          unless pagination.nil? or pagination[:has_more_items].nil? or pagination[:page_number].nil?
            if pagination[:has_more_items]
              page = pagination[:page_number].to_i
              next_page = "#{url}/events/?page=#{page + 1}&token=#{token}"
            end
          end
        rescue Exception => e
          puts "format next_page failed with: #{e.message}"
        end

        # check events
        events = results[:events]
        unless events.nil? or events.empty?
          events.each do |item|
            # create new event
            event = Event.new

            # set required attributes
            event.title = item['name']['text']
            event.url = item['url']
            event.description = convert_description item['description']['html']
            event.timezone = item['start']['timezone']
            event.start = item['start']['local']
            event.end = item['end']['local']
            event.organizer = get_eventbrite_organizer_name(item['organizer_id'],
                                                            token)
            event.online = item['online_event']

            unless item['venue_id'].nil? or item['venue_id'] = 'null'
              address = get_eventbrite_venue item['venue_id'], token
              unless address.nil?
                event.venue = address['localized_address_display']
                event.city = address['city']
                event.country = address['country']
                event.postcode = address['postal_code']
                event.latitude = address['latitude']
                event.longitude = address['longitude']
              end
            end

            # TODO: format contact
            #event.contact = attr['contact']

            # set optional attributes
            event.keywords = get_eventbrite_categories(item['category_id'],
                                                       item['subcategory_id'],
                                                       token)
            unless item['capacity'].nil? or item['capacity'] == 'null'
              event.capacity = item['capacity'].to_i
            end
            # TODO: add fields

            # add event to events array
            add_event(event)
            @ingested += 1
          rescue Exception => e
            @messages << "Extract event fields failed with: #{e.message}"
          end
        end

      end

    rescue Exception => e
      @messages << "#{self.class} failed with: #{e.message}"
    end

    # finished
  end

  def get_eventbrite_venue(id, token)
    result = nil
    unless id.nil? or token.nil? or id == 'null'
      url = "https://www.eventbriteapi.com/venues/#{id}/?token=#{token}"
      venue = get_JSON_response url
      result = venue['address'] unless venue.nil?
    end
    return result
  end

  def get_eventbrite_categories(id, sub_id, token)
    result = []
    unless id.nil? or token.nil? or id == 'null'
      url = "https://www.eventbriteapi.com/categories/#{id}/?token=#{token}"
      categories = get_JSON_response url
      unless categories.nil?
        subcats = categories['subcategories']
        if !subcats.nil? and subcats.kind_of?(Array) and !subcats.empty?
          subcats.each do |sub|
            if sub_id.nil? or sub_id == 'null' or sub_id == sub['id']
              result << sub['name']
            end
          end
        else
          result << categories['name'] if subcats.nil?
        end
      end
    end

    return result
  end

  def get_eventbrite_organizer_name(id, token)
    result = ''
    unless id.nil? or token.nil? or id == 'null'
      url = "https://www.eventbriteapi.com/organizers/#{id}/?token=#{token}"
      organizer = get_JSON_response url
      result = organizer['name'] unless organizer.nil? or organizer == 'null'
    end
    return result
  end

  def process_elixir(url, token)
    # execute REST request
    results = get_JSON_response url
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
          event.url = attr['url'].strip unless attr['url'].nil?
          event.description = convert_description attr['description']
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

  def get_JSON_response(url)
    response = RestClient::Request.new(method: :get,
                                       url: CGI.unescape_html(url),
                                       verify_ssl: false,
                                       headers: { accept: 'application/vnd.api+json' }).execute
    # check response
    raise "invalid response code: #{response.code}" unless response.code == 200
    return JSON.parse(response.to_str)
  end

end
