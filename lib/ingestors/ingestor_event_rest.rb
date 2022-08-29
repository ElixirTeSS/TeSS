require 'icalendar'
require 'open-uri'
require 'csv'
require 'nokogiri'
require 'active_support/core_ext/hash'

module Ingestors
  class IngestorEventRest < IngestorEvent
    def initialize
      super

      @RestSources = [
        { name: 'ElixirTeSS',
          url: 'https://tess.elixir-europe.org/',
          process: method(:process_elixir) },
        { name: 'Digital Skills Programme',
          url: 'https://www.eventbriteapi.com/v3/',
          process: method(:process_eventbrite) },
        { name: 'NL eScienceCenter',
          url: 'https://www.eventbriteapi.com/v3/',
          process: method(:process_eventbrite) },
        { name: 'VU Amsterdam',
          url: 'https://vu-nl.libcal.com/',
          process: method(:process_libcal) },
        { name: 'EUR',
          url: 'https://eur-nl.libcal.com/',
          process: method(:process_libcal) },
        { name: 'SURF',
          url: 'https://www.surf.nl/sitemap.xml',
          process: method(:process_surf) },
        { name: 'DANS',
          url: 'https://dans.knaw.nl/en/agenda/',
          process: method(:process_dans) },
        { name: 'DTL',
          url: 'https://www.dtls.nl/',
          process: method(:process_dtls) },
        { name: 'WUR',
          url: 'https://www.wur.nl/',
          process: method(:process_wur) },
        { name: 'UU',
          url: 'https://www.uu.nl/',
          process: method(:process_uu) },
        { name: 'NWO',
          url: 'https://www.nwo.nl/',
          process: method(:process_nwo) },
        { name: 'UvA',
          url: 'https://www.uva.nl/_restapi/list-json',
          process: method(:process_uva) }
      ]

      # cached API object responses
      @eventbrite_objects = {}
      @VU_objects = {}
    end

    def read(url)
      begin
        process = nil

        # get the rest source
        @RestSources.each do |source|
          process = source[:process] if url.starts_with? source[:url]
        end

        # abort if no source found for url
        raise "REST source not found for URL: #{url}" if process.nil?

        # process url
        process.call(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message} #{e.backtrace}"
        Sentry.capture_exception(e)
      end

      # finished
      nil
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
            if !(pagination.nil? or pagination['has_more_items'].nil? or pagination['page_number'].nil?) && (pagination['has_more_items'])
              page = pagination['page_number'].to_i
              next_page = "#{url}/events/?page=#{page + 1}&token=#{@token}"
            end
          rescue Exception => e
            puts "format next_page failed with: #{e.message}"
            Sentry.capture_exception(e)
          end

          # check events
          events = results['events']
          next if events.nil? or events.empty?

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
                event.online = if item['online_event'].nil? or item['online_event'] == false
                                 false
                               else
                                 true
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
                  item['subcategory_id'], item['category_id']
                )
                event.keywords << category['name'] unless category.nil?
                event.keywords << subcategory['name'] unless subcategory.nil?

                event.capacity = item['capacity'].to_i unless item['capacity'].nil? or item['capacity'] == 'null'

                event.event_types = []
                format = get_eventbrite_format item['format_id']
                unless format.nil?
                  type = convert_event_types format['short_name']
                  event.event_types << type unless type.nil?
                end

                event.eligibility = if item['invite_only'].nil? or !item['invite_only']
                                      'open_to_all'
                                    else
                                      'by_invitation'
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
            Sentry.capture_exception(e)
          end
        end
      rescue Exception => e
        @messages << "#{self.class} failed with: #{e.message}"
        Sentry.capture_exception(e)
      end

      # finished
      @messages << "Eventbrite events ingestor: records read[#{records_read}] inactive[#{records_inactive}] expired[#{records_expired}]"
      nil
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
      Sentry.capture_exception(e)
    end

    def get_eventbrite_venue(id)
      # abort on bad input
      return nil if id.nil? or id == 'null'

      # initialize cache
      @eventbrite_objects[:venues] = {} if @eventbrite_objects[:venues].nil?

      # id not in cache
      add_eventbrite_venue id unless @eventbrite_objects[:venues].keys.include? id

      # return from cache
      @eventbrite_objects[:venues][id]
    end

    def add_eventbrite_venue(id)
      # get from query and add to cache if found
      url = "https://www.eventbriteapi.com/v3/venues/#{id}/?token=#{@token}"
      venue = get_JSON_response url
      @eventbrite_objects[:venues][id] = venue unless venue.nil?
    rescue Exception => e
      @messages << "get Eventbrite Venue failed with: #{e.message}"
      Sentry.capture_exception(e)
    end

    def get_eventbrite_category(id)
      # abort on bad input
      return nil if id.nil? or id == 'null'

      # initialize cache
      @eventbrite_objects[:categories] = {} if @eventbrite_objects[:categories].nil?

      # populate cache
      populate_eventbrite_categories if @eventbrite_objects[:categories].empty?

      # finished
      @eventbrite_objects[:categories][id]
    end

    def populate_eventbrite_categories
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
        unless cats.nil? or !cats.is_a? Array
          cats.each do |cat|
            @eventbrite_objects[:categories][cat['id']] = cat
          end
        end

        # check for next page
        pagination = response['pagination']
        next if pagination.nil?

        has_more_items = pagination['has_more_items']
        page_number = pagination['page_number'] + 1
        url = "https://www.eventbriteapi.com/v3/categories/?page=#{page_number}&token=#{token}"
      end
    rescue Exception => e
      @messages << "get Eventbrite format failed with: #{e.message}"
      Sentry.capture_exception(e)
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
      if !subcategories.nil? and subcategories.is_a?(Array)
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
        Sentry.capture_exception(e)
      end
      subcategories
    end

    def get_eventbrite_organizer(id)
      # abort on bad input
      return nil if id.nil? or id == 'null'

      # initialize cache
      @eventbrite_objects[:organizers] = {} if @eventbrite_objects[:organizers].nil?

      # not in cache
      populate_eventbrite_organizer id unless @eventbrite_objects[:organizers].keys.include? id

      # return from cache
      @eventbrite_objects[:organizers][id]
    end

    def populate_eventbrite_organizer(id)
      # get from query and add to cache if found
      url = "https://www.eventbriteapi.com/v3/organizers/#{id}/?token=#{@token}"
      organizer = get_JSON_response url
      # add to cache
      @eventbrite_objects[:organizers][id] = organizer unless organizer.nil?
    rescue Exception => e
      @messages << "get Eventbrite Venue failed with: #{e.message}"
      Sentry.capture_exception(e)
    end

    def process_elixir(url)
      # execute REST request
      results = get_JSON_response url, 'application/vnd.api+json'
      data = results['data']

      # extract materials from results
      unless data.nil? or data.size < 1
        data.each do |item|
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
          Sentry.capture_exception(e)
        end
      end
    end

    def process_libcal(url)
      # execute REST request
      results = get_JSON_response url
      data = results.to_h['results']

      # extract materials from results
      unless data.nil? or data.size < 1
        data.each do |item|
          # create new event
          event = Event.new

          # extract event details from
          attr = item
          event.title = attr.fetch('title', '')
          event.url = attr.fetch('url', '')&.strip
          event.organizer = attr.fetch('org', '')
          event.description = convert_description attr.fetch('description', '')
          event.start = attr.fetch('startdt', '')
          event.end = attr.fetch('enddt', '')
          event.venue = attr.fetch('location', '')
          if url.starts_with? 'https://vu-nl.libcal.com'
            event.city = 'Amsterdam'
            event.country = 'The Netherlands'
            event.source = 'VU Amsterdam'
          elsif url.starts_with? 'https://eur-nl.libcal.com'
            event.city = 'Rotterdam'
            event.country = 'The Netherlands'
            event.source = 'EUR'
          end
          event.online = attr.fetch('online_event', '')
          event.contact = attr.fetch('orgurl', '')
          event.timezone = 'Amsterdam'

          # array fields
          event.keywords = []
          attr['categories_arr']&.each { |category| event.keywords << category['name'] }

          event.event_types = []
          attr['event_types']&.each do |key|
            value = convert_event_types(key)
            event.event_types << value unless value.nil?
          end

          event.target_audience = []
          attr['audiences']&.each { |audience| event.keywords << audience['name'] }

          event.host_institutions = []
          attr['host-institutions']&.each { |host| event.host_institutions << host }

          # dictionary fields
          event.eligibility = []
          attr['eligibility']&.each do |key|
            value = convert_eligibility(key)
            event.eligibility << value unless value.nil?
          end

          # add event to events array
          add_event(event)
          @ingested += 1
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
          Sentry.capture_exception(e)
        end
      end
    end

    def process_uva(url)
      # execute REST request
      results = get_JSON_response url
      data = results.to_h['items']

      return if data.nil? || data.empty?

      # extract materials from results
      data.each do |item|
        # create new event
        event = Event.new

        # extract event details from
        attr = item
        event.title = attr.fetch('title', '')
        event.url = attr.fetch('url', '')&.strip
        event.organizer = attr.fetch('org', '')
        event.description = convert_description attr.fetch('lead', '')
        event.start = attr.fetch('startDate', '')
        event.end = attr.fetch('endDate', '')
        event.venue = attr.fetch('locations', []).first&.fetch('title', '')
        event.city = 'Amsterdam'
        event.country = 'The Netherlands'
        event.source = 'UvA'
        event.online = attr.fetch('online_event', '')
        event.timezone = 'Amsterdam'

        # array fields
        event.keywords = attr.fetch('taxonomy', []).map(&:values).flatten

        event.event_types = attr.fetch('eventType', []).map { |t| convert_event_types(t) }

        # add event to events array
        add_event(event)
        @ingested += 1
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
        Sentry.capture_exception(e)
      end
    end

    def process_surf(url)
      Hash.from_xml(Nokogiri::XML(URI.open(url)).to_s)['sitemapindex']['sitemap'].each do |page|
        Hash.from_xml(Nokogiri::XML(URI.open(page['loc'])).to_s)['urlset']['url'].each do |event_page|
          next unless event_page['loc'].include?('/en/agenda/')

          sleep(1)
          data_json = Nokogiri::HTML5.parse(URI.open(event_page['loc'])).css('script[type="application/ld+json"]')
          next unless data_json.length > 0

          data = JSON.parse(data_json.first.text)
          begin
            # create new event
            event = Event.new

            # extract event details from
            attr = data['@graph'].first
            event.title = attr['name']
            event.url = attr['url']&.strip
            event.description = convert_description attr['description']
            event.start = attr['startDate']
            event.end = attr['endDate']
            event.venue = if attr['location'].is_a?(Array)
                            attr['location'].join(' - ')
                          else
                            attr['location']
                          end
            event.source = 'SURF'
            event.online = true
            event.timezone = 'Amsterdam'

            # add event to events array
            add_event(event)
            @ingested += 1
          rescue Exception => e
            @messages << "Extract event fields failed with: #{e.message}"
            Sentry.capture_exception(e)
          end
        end
      end
    end

    def process_dans(url)
      4.times.each do |i| # always check the first 4 pages, # of pages could be increased if needed
        sleep(1)
        event_page = Nokogiri::HTML5.parse(URI.open(url + i.to_s)).css("div[id='nieuws_item_section']")
        event_page.each do |event_data|
          event = Event.new

          # dates
          dates = event_data.css("div[id='nieuws_image_date_row']").css('p').css('span')
          event.start = dates[0].children.to_s.to_time
          event.end = dates[1].children.to_s.to_time if dates.length == 2

          data = event_data.css("div[id='nieuws_content_row']").css('div')[0].css('div')[0]
          event.title = data.css("div[id='agenda_titel']").css('h3')[0].children

          event.keywords = []
          data.css("div[id='cat_nieuws_item']").css('p').css('span').each do |key|
            value = key.children
            event.keywords << value unless value.nil?
          end
          data.css("div[id='tag_nieuws']").css('p').css('span').each do |key|
            value = key.children
            event.keywords << value unless value.nil?
          end

          event.description = data.css("p[class='dmach-acf-value dmach-acf-video-container']")[0].children.to_s

          event.url = data.css("a[id$='_link']")[0]['href'].to_s

          event.source = 'DANS'
          event.timezone = 'Amsterdam'

          add_event(event)
          @ingested += 1
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
          Sentry.capture_exception(e)
        end
      end
    end

    def process_dtls(url)
      ['courses/', 'events/'].each do |url_suffix|
        docs = Nokogiri::XML(URI.open(url + url_suffix + 'feed')).xpath('//item')
        docs.each do |event_item|
          begin
            event = Event.new
            event.event_types = ['workshops_and_courses']
            event_item.element_children.each do |element|
              case element.name
              when 'title'
                event.title = element.text
              when 'link'
                # Use GUID field as probably more stable
                # event.url = element.text
              when 'creator'
                # event.creator = element.text
                # no creator field. Not sure needs one
              when 'guid'
                event.url = element.text
              when 'description'
                event.description = convert_description element.text
              when 'location'
                event.venue = element.text
                loc = element.text.split(',')
                event.city = loc.first.strip
                event.country = loc.last.strip
              when 'provider'
                event.organizer = element.text
              when 'startdate', 'courseDate'
                event.start = element.text.to_s.to_time
              when 'enddate', 'courseEndDate'
                event.end = element.text.to_s.to_time
              when 'latitude'
                event.latitude = element.text
              when 'longitude'
                event.longitude = element.text
              when 'pubDate'
                # Not really needed
              else
                # chuck away
              end
            end
          end
          event.end = event.start if event.end.nil?
          event.source = 'DTL'
          event.timezone = 'Amsterdam'
          add_event(event)
          @ingested += 1
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
          Sentry.capture_exception(e)
        end
      end
    end

    def process_wur(url)
      docs = Nokogiri::XML(URI.open(url)).xpath('//item')
      docs.each do |event_item|
        begin
          event = Event.new
          event.event_types = ['workshops_and_courses']
          event_item.element_children.each do |element|
            case element.name
            when 'title'
              event.title = element.text
            when 'link'
              event.url = element.text
              # only include events which have this in their path
              next unless event.url.include?('activity') || event.url.include?('Research-Results')
            when 'creator'
              # event.creator = element.text
              # no creator field. Not sure needs one
            when 'description'
              event.description = convert_description element.text
            when 'location'
              event.venue = element.text
              loc = element.text.split(',')
              event.city = loc.first.strip
              event.country = loc.last.strip
            when 'provider'
              event.organizer = element.text
            when 'startdate', 'courseDate'
              event.start = element.text.to_s.to_time
            when 'enddate', 'courseEndDate'
              event.end = element.text.to_s.to_time
            when 'latitude'
              event.latitude = element.text
            when 'longitude'
              event.longitude = element.text
            when 'pubDate'
              # Not really needed
            else
              # chuck away
            end
          end
        end
        # Now fetch the page to get the event date (until it is added to the RSS feed)
        unless event.start and !event.url.starts_with('https://')
          # should we do more against data exfiltration? URI.open is a known hazard
          page = Nokogiri::XML(URI.open(event.url))
          event.start = page.xpath('//th[.="Date"]').first&.parent&.xpath('td')&.last&.text&.strip&.to_time
          # in this case also grab the venue
          event.venue = page.xpath('//th[.="Venue"]').first&.parent&.xpath('td')&.last&.text
          sleep 1
        end

        event.end = event.start if event.end.nil?
        event.source = 'WUR'
        event.timezone = 'Amsterdam'

        add_event(event)
        @ingested += 1
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
        Sentry.capture_exception(e)
      end
    end

    def process_uu(url)
      # instead of fetching all content at the same time we have to make a loop
      # over the categories, since in the RSS feed there is no information
      # on which category an event belongs to.
      # translate here only to the names given on the UU site, use the event_types match field
      # to further match those.
      categories = {
        # en
        4301 => 'workshops, masterclasses',
        4296 => 'lectures',
        4295 => 'training',
        4293 => 'congresses, symposia',
        # nl
        4043 => 'workshops, masterclasses',
        1_916_692 => 'lectures', # lezingen, debatten,
        1_916_689 => 'training', # cursussen, trainingen
        174_593 => 'congressen, symposia'
      }

      url.split('=').last.split(',').each do |category_id|
        sub_url = url.split('=').first + '=' + category_id
        docs = Nokogiri::XML(URI.open(sub_url)).xpath('//item')
        docs.each do |event_item|
          begin
            event = Event.new
            event.event_types = [categories.fetch(category_id, 'workshops_and_courses')]
            event_item.element_children.each do |element|
              case element.name
              when 'title'
                event.title = element.text
              when 'link'
                event.url = element.text
              when 'creator'
                # event.creator = element.text
                # no creator field. Not sure needs one
              when 'description'
                event.description = convert_description element.text
              when 'location'
                event.venue = element.text
                loc = element.text.split(',')
                event.city = loc.first.strip
                event.country = loc.last.strip
              when 'provider'
                event.organizer = element.text
              when 'startdate', 'courseDate'
                event.start = element.text.to_s.to_time
              when 'enddate', 'courseEndDate'
                event.end = element.text.to_s.to_time
              when 'latitude'
                event.latitude = element.text
              when 'longitude'
                event.longitude = element.text
              when 'pubDate'
                # Not really needed
              else
                # chuck away
              end
            end
          end
          # fetch the ICS file to get the date and location info
          nid = event_item.xpath('guid').text
          if nid
            ics_url = "https://www.uu.nl/node/#{nid}/ics"
            ical_event = Icalendar::Event.parse(URI.open(ics_url).set_encoding('utf-8')).first
            event.start ||= ical_event.dtstart
            event.end ||= ical_event.dtend
            event.venue ||= ical_event.location
            sleep 1
          end

          event.end = event.start if event.end.nil?
          event.source = 'WUR'
          event.timezone = 'Amsterdam'

          # the below code allows fetching the long description, at the cost of a
          # page load per event.
          # Now fetch the page to get the event date (until it is added to the RSS feed)
          # if event.url.starts_with('https://')
          # should we do more against data exfiltration? URI.open is a known hazard
          # page = Nokogiri::XML(URI.open(event.url))
          # event.description = convert_description page.css('.content-block__inner').first.inner_html
          # end
          add_event(event)
          @ingested += 1
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
          Sentry.capture_exception(e)
        end
      end
    end

    def process_nwo(url)
      4.times.each do |i| # always check the first 4 pages, # of pages could be increased if needed
        sleep(1)
        event_page = Nokogiri::HTML5.parse(URI.open("#{url}?page=#{i}")).css(".overviewContent > .listing-cards > li.list-item > a")
        event_page.each do |event_data|
          event = Event.new

          # dates
          event.title = event_data.css('h3.card__title').text
          event.timezone = 'Amsterdam'
          event.start, event.end = parse_dates(event_data.css('.card__subtitle').text, event.timezone)

          event.keywords = []
          event.description = convert_description event_data.css('.card__intro').inner_html

          event.url = "https://www.nwo.nl#{event_data['href']}"

          event.source = 'NWO'

          add_event(event)
          @ingested += 1
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
          Sentry.capture_exception(e)
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
end
