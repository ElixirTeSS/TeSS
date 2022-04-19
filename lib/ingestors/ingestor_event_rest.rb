require 'ingestors/ingestor_event'
require 'open-uri'
require 'csv'

class IngestorEventRest < IngestorEvent

  def initialize
    super

    @RestSources = [
      { name: 'ElixirTeSS',
        url: 'https://tess.elixir-europe.org/',
        process: method(:process_elixir) },
      { name: 'Eventbrite API v3',
        url: 'https://www.eventbriteapi.com/v3/',
        process: method(:process_eventbrite) }
    ]

    # cached API object responses
    @eventbrite_objects = {}
  end

  def read(url)
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
      process.call(url)

    rescue Exception => e
      @messages << "#{self.class.name} failed with: #{e.message}"
    end

    # finished
    return
  end

  private

  def process_eventbrite(url)
    records_read = 0
    records_inactive = 0
    records_expired = 0

    begin
      # initialise next_page
      next_page = "#{url}/events/?status=live&token=#{@token}"

      while next_page
        # execute REST request
        results = get_JSON_response next_page

        # check next page
        next_page = nil
        pagination = results['pagination']
        begin
          unless pagination.nil? or pagination['has_more_items'].nil? or pagination['page_number'].nil?
            if pagination['has_more_items']
              page = pagination['page_number'].to_i
              next_page = "#{url}/events/?page=#{page + 1}&token=#{@token}"
            end
          end
        rescue Exception => e
          puts "format next_page failed with: #{e.message}"
        end

        # check events
        events = results['events']
        unless events.nil? or events.empty?
          events.each do |item|
            records_read += 1
            if item['status'].nil? or item['status'] != 'live'
              records_inactive += 1
            else
              # create new event
              event = Event.new

              # check for expired
              event.timezone = item['start']['timezone']
              event.start = item['start']['local']
              event.end = item['end']['local']
              if event.expired?
                records_expired += 1
              else
                # set required attributes
                event.title = item['name']['text'] unless item['name'].nil?
                event.url = item['url']
                event.description = convert_description item['description']['html'] unless item['description'].nil?
                if item['online_event'].nil? or item['online_event'] == false
                  event.online = false
                else
                  event.online = true
                end

                # organizer
                organizer = get_eventbrite_organizer item['organizer_id']
                event.organizer = organizer['name'] unless organizer.nil?

                # address fields
                venue = get_eventbrite_venue item['venue_id']
                unless venue.nil? or venue['address'].nil?
                  address = venue['address']
                  venue = address['address_1']
                  venue += (', ' + address['address_2']) unless address['address_2'].blank?
                  event.venue = venue
                  event.city = address['city']
                  event.country = address['country']
                  event.postcode = address['postal_code']
                  event.latitude = address['latitude']
                  event.longitude = address['longitude']
                end

                # set optional attributes
                event.keywords = []
                category = get_eventbrite_category item['category_id']
                subcategory = get_eventbrite_subcategory(
                  item['subcategory_id'], item['category_id'])
                event.keywords << category['name'] unless category.nil?
                event.keywords << subcategory['name'] unless subcategory.nil?

                unless item['capacity'].nil? or item['capacity'] == 'null'
                  event.capacity = item['capacity'].to_i
                end

                event.event_types = []
                format = get_eventbrite_format item['format_id']
                unless format.nil?
                  type = convert_event_types format['short_name']
                  event.event_types << type unless type.nil?
                end

                if item['invite_only'].nil? or !item['invite_only']
                  event.eligibility = 'open_to_all'
                else
                  event.eligibility = 'by_invitation'
                end

                if item['is_free'].nil? or !item['is_free']
                  event.cost_basis = 'charge'
                  event.cost_currency = item['currency']
                else
                  event.cost_basis = 'free'
                end

                # add event to events array
                add_event(event)
                @ingested += 1
              end
            end
          rescue Exception => e
            @messages << "Extract event fields failed with: #{e.message}"
          end
        end
      end
    rescue Exception => e
      @messages << "#{self.class} failed with: #{e.message}"
    end

    # finished
    @messages << "Eventbrite events ingestor: records read[#{records_read}] inactive[#{records_inactive}] expired[#{records_expired}]"
    return
  end

  def get_eventbrite_format(id)
    # initialise cache
    @eventbrite_objects[:formats] = {} if @eventbrite_objects[:formats].nil?

    # populate cache if empty
    populate_eventbrite_formats if @eventbrite_objects[:formats].empty?

    # return result
    @eventbrite_objects[:formats][id]
  end

  def populate_eventbrite_formats
    begin
      # get formats from Eventbrite
      url = "https://www.eventbriteapi.com/v3/formats/?token=#{@token}"
      response = get_JSON_response url
      # process formats
      response['formats'].each do |format|
        # add each item to the cache
        @eventbrite_objects[:formats][format['id']] = format
      end
    rescue Exception => e
      @messages << "populate Eventbrite formats failed with: #{e.message}"
    end
  end

  def get_eventbrite_venue(id)
    # abort on bad input
    return nil if id.nil? or id == 'null'

    # initialize cache
    @eventbrite_objects[:venues] = {} if @eventbrite_objects[:venues].nil?

    # id not in cache
    unless @eventbrite_objects[:venues].keys.include? id
      add_eventbrite_venue id
    end

    # return from cache
    @eventbrite_objects[:venues][id]
  end

  def add_eventbrite_venue(id)
    begin
      # get from query and add to cache if found
      url = "https://www.eventbriteapi.com/v3/venues/#{id}/?token=#{@token}"
      venue = get_JSON_response url
      @eventbrite_objects[:venues][id] = venue unless venue.nil?
    rescue Exception => e
      @messages << "get Eventbrite Venue failed with: #{e.message}"
    end
  end

  def get_eventbrite_category(id)
    # abort on bad input
    return nil if id.nil? or id == 'null'

    # initialize cache
    @eventbrite_objects[:categories] = {} if @eventbrite_objects[:categories].nil?

    # populate cache
    if @eventbrite_objects[:categories].empty?
      populate_eventbrite_categories
    end

    # finished
    @eventbrite_objects[:categories][id]
  end

  def populate_eventbrite_categories
    begin
      # initialise pagination
      has_more_items = true
      url = "https://www.eventbriteapi.com/v3/categories/?token=#{@token}"

      # query until no more pages
      while has_more_items
        # infinite loop guard
        has_more_items = false

        # execute query
        response = get_JSON_response url

        # process categories
        cats = response['categories']
        unless cats.nil? or !cats.kind_of? Array
          cats.each do |cat|
            @eventbrite_objects[:categories][cat['id']] = cat
          end
        end

        # check for next page
        pagination = response['pagination']
        unless pagination.nil?
          has_more_items = pagination['has_more_items']
          page_number = pagination['page_number'] + 1
          url = "https://www.eventbriteapi.com/v3/categories/?page=#{page_number}&token=#{token}"
        end
      end
    rescue Exception => e
      @messages << "get Eventbrite format failed with: #{e.message}"
    end
  end

  def get_eventbrite_subcategory(id, category_id)
    # abort on bad input
    return nil if id.nil? or id == 'null'

    # get category
    category = get_eventbrite_category category_id
    return nil if category.nil?

    # get subcategories from cache
    subcategories = category['subcategories']

    # get subcategories from query
    subcategories = populate_eventbrite_subcategories id, category if subcategories.nil?

    # check for subcategory
    if !subcategories.nil? and subcategories.kind_of?(Array)
      subcategories.each { |sub| return sub if sub['id'] == id }
    end

    # not found
    nil
  end

  def populate_eventbrite_subcategories(id, category)
    subcategories = nil
    begin
      url = "#{category['resource_uri']}?token=#{@token}"
      response = get_JSON_response url
      # updated cached category
      @eventbrite_objects[:categories][id] = response
      subcategories = response['subcategories']
    rescue Exception => e
      @messages << "get Eventbrite subcategory failed with: #{e.message}"
    end
    return subcategories
  end

  def get_eventbrite_organizer(id)
    # abort on bad input
    return nil if id.nil? or id == 'null'

    # initialize cache
    @eventbrite_objects[:organizers] = {} if @eventbrite_objects[:organizers].nil?

    # not in cache
    unless @eventbrite_objects[:organizers].keys.include? id
      populate_eventbrite_organizer id
    end

    # return from cache
    @eventbrite_objects[:organizers][id]
  end

  def populate_eventbrite_organizer(id)
    begin
      # get from query and add to cache if found
      url = "https://www.eventbriteapi.com/v3/organizers/#{id}/?token=#{@token}"
      organizer = get_JSON_response url
      # add to cache
      @eventbrite_objects[:organizers][id] = organizer unless organizer.nil?
    rescue Exception => e
      @messages << "get Eventbrite Venue failed with: #{e.message}"
    end
  end

  def process_elixir(url)
    # execute REST request
    results = get_JSON_response url, 'application/vnd.api+json'
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
  end

  def get_JSON_response(url, accept_params = 'application/json')
    response = RestClient::Request.new(method: :get,
                                       url: CGI.unescape_html(url),
                                       verify_ssl: false,
                                       headers: { accept: accept_params }).execute
    # check response
    raise "invalid response code: #{response.code}" unless response.code == 200
    JSON.parse(response.to_str)
  end

end
