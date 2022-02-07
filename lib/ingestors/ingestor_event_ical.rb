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
      when '.ical', 'ics'
        process_icalendar url
      when 'sitemap.xml'
        process_sitemap url
      end
    end
  end

  private

  def process_sitemap url
    processed = 0
    # TODO: find urls for individual icalendar files
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
    # TODO: process individual ics file

  end
end
