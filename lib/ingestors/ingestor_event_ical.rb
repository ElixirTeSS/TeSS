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
      case url.to_s.downcase.end_with?
      when 'sitemap.xml'
        process_sitemap url
      else
        process_icalendar url
      end
    end
  end

  private

  def process_sitemap url
    processed = 0
    # find urls for individual icalendar files
    begin
      sitemap = Nokogiri::XML.parse(open_url(url))
      locs = sitemap.xpath('/ns:urlset/ns:url/ns:loc', {
        'ns' => 'http://www.sitemaps.org/schemas/sitemap/0.9'
      })
      loc.each { |u| processed += process_icalendar(u) }
    rescue Exception => e
      Scraper.log("Extract from sitemap[#{url}] failed with: #{e}", 2)
    end

    return processed
  end

  def process_icalendar url
    # process individual ics file
    processed = 0
    query = '?ical=true'

    # append query  (if required)
    url.ends_with? query ? file_url = url : file_url + query

    # process file
    begin
      file = open_url(file_url)
      events = Icalendar::Event.parse(file.set_encoding('utf-8'))
      # process each event
      events.each { |e| processed += 1 if process_event(e,url) }
    rescue Exception => e
      Scraper.log "process file url#{file_url} failed with: #{e.message}", 3
    end
    return processed
  end


  def process_event(calevent, url)
    result = false

    begin
      # set fields
      event = Event.new
      event.url = url
      event.title = calevent.summary.to_s
      event.description = calevent.description
      event.timezone = calevent.dtstart.ical_params['tzid']
      event.start = calevent.dtstart
      event.end = calevent.dtend
      event.keywords = calevent.categories
      event.venue = calevent.location
      event.online = true if calevent.location.downcase.include?('online')

      # store event
      @events << event
      result = true
    rescue Exception => e
      Scraper.log "process_event failed with: #{e.message}", 3
    end

    return result
  end

end
