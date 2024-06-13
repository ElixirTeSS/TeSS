require 'icalendar'
require 'nokogiri'
require 'open-uri'
require 'tzinfo'

module Ingestors
  class IcalIngestor < Ingestor
    attr_reader :icalendars

    def self.config
      {
        key: 'ical',
        title: 'iCalendar',
        category: :events
      }
    end

    def read(url)
      unless url.nil?
        if url.to_s.downcase.end_with? 'sitemap.xml'
          process_sitemap url
        else
          process_icalendar url
        end
      end
    end

    private

    def process_sitemap(url)
      # find urls for individual icalendar files
      begin
        sitemap = Nokogiri::XML.parse(open_url(url, raise: true))
        locs = sitemap.xpath('/ns:urlset/ns:url/ns:loc', {
                               'ns' => 'http://www.sitemaps.org/schemas/sitemap/0.9'
                             })
        locs.each do |loc|
          process_icalendar(loc.text)
        end
      rescue Exception => e
        @messages << "Extract from sitemap[#{url}] failed with: #{e.message}"
      end

      # finished
      nil
    end

    def full_url(url)
      # append query  (if required)
      query = '?ical=true'
      return url + query unless url.to_s.downcase.ends_with? query
      url
    end

    def fetch_events(file_url)
      Icalendar::Event.parse(open_url(file_url,
                                      raise: true).set_encoding('utf-8'))
    end

    def process_icalendar(url)
      # process individual ics file
      file_url = full_url(url)

      begin
        # process file
        events = fetch_events(file_url)
        events.each do |e|
          process_event(e)
        end
      rescue Exception => e
        @messages << "Process file url[#{file_url}] failed with: #{e.message}"
      end

      # finished
      nil
    end

    def ical_event_online?(calevent)
      calevent.location.downcase.include?('online')
    end

    def extract_event_start(calevent)
      calevent.dtstart&.to_time
    end

    def extract_event_timezone(calevent)
      return nil if calevent.dtstart.nil?
      tzid = calevent.dtstart.ical_params['tzid']
      # Sometimes it's a string ...
      return tzid if tzid.is_a?(String)
      # Sometimes it's an array ...
      return tzid.first.to_s if !tzid.nil? and tzid.size > 0
    end

    def extract_url(calevent)
      calevent.url.to_s
    end

    def process_event(calevent)
      # puts "calevent: #{calevent.inspect}"
      begin
        # set fields
        event = OpenStruct.new
        event.url = extract_url(calevent)
        event.title = calevent.summary.to_s
        event.description = process_description calevent.description

        # puts "\n\ncalevent.description = #{calevent.description}"
        # puts "\n\n...        converted = #{event.description}"

        event.end = calevent.dtend&.to_time
        event.start = extract_event_start(calevent)
        event.timezone = extract_event_timezone(calevent)

        event.venue = calevent.location.to_s
        if ical_event_online?(calevent)
          event.online = true
          event.city = nil
          event.postcode = nil
          event.country = nil
        else
          location = convert_location(calevent.location)
          event.city = location['suburb'] unless location['suburb'].nil?
          event.country = location['country'] unless location['country'].nil?
          event.postcode = location['postcode'] unless location['postcode'].nil?
        end
        event.keywords = []
        unless calevent.categories.nil? or calevent.categories.first.nil?
          cats = calevent.categories.first
          if cats.is_a?(Icalendar::Values::Array)
            cats.each do |item|
              event.keywords << item.to_s.lstrip
            end
          else
            event.keywords << cats.to_s.strip
          end
        end

        # store event
        @events << event
      rescue Exception => e
        @messages << "Process iCalendar failed with: #{e.message}"
      end

      # finished
      nil
    end

    def process_description(input)
      return input if input.nil?

      convert_description(input.to_s.gsub(/\R/, '<br />'))
    end
  end
end
