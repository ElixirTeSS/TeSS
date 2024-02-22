require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class OsciIngestor < Ingestor
    def self.config
      {
        key: 'osci_event',
        title: 'OSCI Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_osci(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_osci(url)
      month = Time.zone.now.month
      year = Time.zone.now.year
      (1..12).each do |i|
        unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/osci.yml')
          sleep(1)
        end
        scrape_url = "https://osc-international.com/my-calendar/?format=calendar&month=#{i}&yr=#{i >= month ? year : year + 1}"
        event_page = Nokogiri::HTML5.parse(open_url(scrape_url.to_s, raise: true)).css("div[id='my-calendar']")[0].css("tbody")[0].css("td")
        event_page.each do |event_data|
          next if event_data.get_attribute('class').include?('no-events')

          beep = event_data.css("div[id*=calendar-my-calendar]")
          beep.each do |boop|
            event = OpenStruct.new
            el = boop.css("h3[class='event-title summary']")[0]
            url_str = el.css("a")[0].get_attribute('href')
            event.url = scrape_url + url_str

            el2 = boop.css("div[id='#{url_str.gsub('#', '')}']")[0]
            event.title = el2.css("h4[class='mc-title']")[0].text.strip
            event.venue = el2.css("div[class='mc-location']")[0].css("strong[class='location-link']")[0].text.strip

            if el2.css("div[class='time-block']")[0].css("span[class='event-time dtstart']").count.positive?
              event.start = Time.zone.parse(el2.css("div[class='time-block']")[0].css("span[class='event-time dtstart']")[0].css("time")[0].get_attribute('datetime'))
              event.end = Time.zone.parse(el2.css("div[class='time-block']")[0].css("span[class='end-time dtend']")[0].css("time")[0].get_attribute('datetime'))
            else
              event.start = Time.zone.parse(el2.css("div[class='time-block']")[0].css("span[class='mc-start-date dtstart']")[0].get_attribute('content'))
              if el2.css("div[class='time-block']")[0].css("span[class='event-time dtend']").count.positive?
                event.end = Time.zone.parse(el2.css("div[class='time-block']")[0].css("span[class='event-time dtend']")[0].text.strip)
              else
                event.end = event.start
              end
            end

            # parsed datetimes are always 2 hours off
            event.start += 2.hours
            event.end += 2.hours

            event.source = 'OSCI'
            event.timezone = 'Amsterdam'
            event.set_default_times

            add_event(event)
          end
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end
