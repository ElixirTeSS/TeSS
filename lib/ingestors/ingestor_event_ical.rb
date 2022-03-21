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
    processed = 0
    messages = []
    # find urls for individual icalendar files
    begin
      sitemap = Nokogiri::XML.parse(open(url))
      locs = sitemap.xpath('/ns:urlset/ns:url/ns:loc', {
        'ns' => 'http://www.sitemaps.org/schemas/sitemap/0.9'
      })
      locs.each do |loc|
        icals_processed, ical_messages = process_icalendar(loc.text)
        processed += icals_processed
        messages << ical_messages
      end
    rescue Exception => e
      messages << "Extract from sitemap[#{url}] failed with: #{e}"
    end

    # finished
    return processed, messages
  end

  def process_icalendar url
    # process individual ics file
    processed = 0
    messages = []
    query = '?ical=true'

    begin
      # append query  (if required)
      file_url = url
      file_url << query unless url.to_s.downcase.ends_with? query

      # process file
      events = Icalendar::Event.parse(open(file_url).set_encoding('utf-8'))

      # process each event
      events.each do |e|
        result, event_messages = process_event(e)
        processed += 1 if result
        messages += event_messages
      end
    rescue Exception => e
      messages << "Process file url[#{file_url}] failed with: #{e.message}"
    end

    # finished
    return processed, messages
  end

  def process_event(calevent)
    processed = 0
    messages = []

    begin
      # set fields
      event = Event.new
      event.url = calevent.url.to_s
      event.title = calevent.summary.to_s
      event.description = convert_description(calevent.description.to_s)
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
      if !calevent.categories.nil? and !calevent.categories.first.nil?
        calevent.categories.first.each { |item| event.keywords << item.to_s.lstrip }
      end

      # store event
      @events << event
      processed += 1
    rescue Exception => e
      messages << "Process iCalendar failed with: #{e.message}"
    end

    return processed, messages
  end

end
