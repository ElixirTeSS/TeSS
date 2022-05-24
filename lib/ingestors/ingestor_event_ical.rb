require 'ingestors/ingestor_event'
require 'icalendar'
require 'nokogiri'
require 'open-uri'
require 'tzinfo'

class IngestorEventIcal < IngestorEvent

  def initialize
    super
  end

  def read (url)
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
      sitemap = Nokogiri::XML.parse(open(url))
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
    return
  end

  def process_icalendar(url)
    # process individual ics file
    query = '?ical=true'

    begin
      # append query  (if required)
      file_url = url
      file_url << query unless url.to_s.downcase.ends_with? query

      # process file
      events = Icalendar::Event.parse(open(file_url).set_encoding('utf-8'))

      # process each event
      events.each do |e|
        process_event(e)
      end

    rescue Exception => e
      @messages << "Process file url[#{file_url}] failed with: #{e.message}"
    end

    # finished
    return
  end

  def process_event(calevent)
    #puts "calevent: #{calevent.inspect}"
    begin
      # set fields
      event = Event.new
      event.url = calevent.url.to_s
      event.title = calevent.summary.to_s
      event.description = process_description calevent.description

      #puts "\n\ncalevent.description = #{calevent.description}"
      #puts "\n\n...        converted = #{event.description}"

      event.end = calevent.dtend
      if !calevent.dtstart.nil?
        dtstart = calevent.dtstart
        event.start = dtstart
        tzid = dtstart.ical_params['tzid']
        if !tzid.nil? and tzid.size > 0
          event.timezone = tzid.first.to_s
        end
      end

      event.venue = calevent.location.to_s
      if calevent.location.downcase.include?('online')
        event.online = true
        event.city = nil
        event.postcode = nil
      else
        location = convert_location(calevent.location)
        event.city = location['suburb'] unless location['suburb'].nil?
        event.country = location['country'] unless location['country'].nil?
        event.postcode = location['postcode'] unless location['postcode'].nil?
      end
      event.keywords = []
      unless calevent.categories.nil? or calevent.categories.first.nil?
        cats = calevent.categories.first
        if cats.kind_of?(Icalendar::Values::Array)
          cats.each do |item|
            event.keywords << item.to_s.lstrip
          end
        else
          event.keywords << cats.to_s.strip
        end
      end

      # store event
      @events << event
      @ingested += 1
    rescue Exception => e
      @messages << "Process iCalendar failed with: #{e.message}"
    end

    # finished
    return
  end

  def process_description(input)
    return input if input.nil?
    return convert_description(input.to_s.gsub(/\R/, '<br />'))
  end

end
