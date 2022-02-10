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

  def process_sitemap url
    #puts "process_sitemap: #{url}"
    processed = 0
    # find urls for individual icalendar files
    begin
      sitemap = Nokogiri::XML.parse(open(url))
      locs = sitemap.xpath('/ns:urlset/ns:url/ns:loc', {
        'ns' => 'http://www.sitemaps.org/schemas/sitemap/0.9'
      })
      locs.each { |loc| processed += process_icalendar(loc.text) }
    rescue Exception => e
      Scraper.log("Extract from sitemap[#{url}] failed with: #{e}", 2)
    end

    return processed
  end

  def process_icalendar url
    #puts "process_icalendar: #{url}"
    # process individual ics file
    processed = 0
    query = '?ical=true'

    # append query  (if required)
    file_url = url
    file_url << query unless url.to_s.downcase.ends_with? query

    # process file
    begin
      events = Icalendar::Event.parse(open(file_url).set_encoding('utf-8'))
      # process each event
      events.each { |e| processed += 1 if process_event(e, url) }
    rescue Exception => e
      Scraper.log "process file url[#{file_url}] failed with: #{e.message}", 3
    end
    return processed
  end

  def process_event(calevent, url)

    result = false
    begin
      # set fields
      event = Event.new
      event.url = url.to_s
      event.title = calevent.summary.to_s
      event.description = calevent.description.to_s
      event.timezone = calevent.dtstart.ical_params['tzid']
      event.start = calevent.dtstart
      event.end = calevent.dtend
      event.venue = calevent.location.to_s
      if calevent.location.downcase.include?('online')
        event.online = true
      else
        location = convert_location(calevent.location)
        
        event.city = location[:city]
        event.country = location[:country]
      end
      event.keywords = []
      if !calevent.categories.nil? and calevent.categories.size > 0
        calevent.categories.each { |item| event.keywords << item.to_s }
      end

      # store event
      @events << event
      result = true
    rescue Exception => e
      Scraper.log "process_event failed with: #{e.message}", 3
    end

    return result
  end

end
