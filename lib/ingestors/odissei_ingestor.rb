require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class OdisseiIngestor < Ingestor
    def self.config
      {
        key: 'odissei_event',
        title: 'ODISSEI Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_odissei(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_odissei(url)
      odissei_url = 'https://odissei-data.nl/calendar/'

      workshop_title_list = []
      workshop_url_list = []
      event_page = Nokogiri::HTML5.parse(open_url(odissei_url.to_s, raise: true)).css("div[class='tribe-events-calendar-list']").first.css("div[class='tribe-common-g-row tribe-events-calendar-list__event-row']")
      event_page.each do |event_section|
        event = OpenStruct.new
        el = event_section.css("div[class='tribe-events-calendar-list__event-details tribe-common-g-col']").first
        event.title = el.css("a[class='tribe-events-calendar-list__event-title-link tribe-common-anchor-thin']").first.text.gsub("\n", ' ').gsub("\t", '')
        event.url = el.css("a[class='tribe-events-calendar-list__event-title-link tribe-common-anchor-thin']").first.get_attribute('href')
        event.description = el.css("div[class='tribe-events-calendar-list__event-description tribe-common-b2 tribe-common-a11y-hidden']").first.css('p').first.text
        unless (Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/odissei.yml'))
          sleep(1)
        end
        el = Nokogiri::HTML5.parse(open_url(event.url.to_s, raise: true)).css("div[id='tribe-events-content']").first
        venue_css = el&.css("div[class='tribe-events-meta-group tribe-events-meta-group-venue']")&.first&.css("dl")
        if !venue_css
          next
        end
        event.venue = recursive_description_func(venue_css).gsub("\n", ' ').gsub("\t", '')
        times = scrape_start_and_end_time(el.css("div[class='tribe-events-meta-group tribe-events-meta-group-details']").first)
        event.start = times[0]
        event.end = times[1]
        event.source = 'ODISSEI'
        event.timezone = 'Amsterdam'
        event.set_default_times
        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end

def scrape_start_and_end_time(el)
  start_date = el&.css("abbr[class='tribe-events-abbr tribe-events-start-date published dtstart']")&.first
  start_time = el&.css("div[class='tribe-events-abbr tribe-events-start-time published dtstart']")&.first
  start_date_time = el&.css("abbr[class='tribe-events-abbr tribe-events-start-datetime updated published dtstart']")&.first
  end_date_time = el&.css("abbr[class='tribe-events-abbr tribe-events-end-datetime dtend']")&.first
  if start_time
    start_date = start_time.get_attribute('title').strip
    end_date = start_date
    time = start_time.text.strip
    if time.include?('-')
      start_time = time.split('-')[0].strip
      end_time = time.split('-')[1].strip
    else
      start_time = time
      end_time = [time.to_i + 1, 18].max.to_s + ':00'
    end
  elsif start_date_time
    start_date = start_date_time.get_attribute('title').strip
    start_time = start_date_time.text.split('@').last.strip
    end_date = end_date_time.get_attribute('title').strip
    end_time = end_date_time.text.split('@').last.strip
  end
  event_start = Time.zone.parse(start_date + ' ' + start_time)
  event_end = Time.zone.parse(end_date + ' ' + end_time)
  return [event_start, event_end]
end

def recursive_description_func(css, res='')
  if css.length == 1
    res += css.text.strip
  else
    css.each do |css2|
      res += recursive_description_func(css2, res)
    end
  end
  res
end
