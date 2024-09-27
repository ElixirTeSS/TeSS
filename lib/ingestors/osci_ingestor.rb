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

    def process_osci(_url)
      month = Time.zone.now.month
      year = Time.zone.now.year
      (1..12).each do |i|
        sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/osci.yml')
        scrape_url = "https://osc-international.com/my-calendar/?format=calendar&month=#{i}&yr=#{i >= month ? year : year + 1}"
        event_page = Nokogiri::HTML5.parse(open_url(scrape_url.to_s, raise: true)).css('#my-calendar > .mc-content > table.my-calendar-table > tbody > tr > td')
        event_page.each do |event_data|
          next if event_data.get_attribute('class').include?('no-events')

          event_cal = event_data.css('article.calendar-event')
          event_cal.each do |boop|
            event = OpenStruct.new
            el = boop.css('div.details')
            url_str = el.css('a')[0].get_attribute('href')
            event.url = scrape_url + url_str

            event.title = el.css('h4.mc-title')[0].text.strip
            event.venue = el.css('.mc-location')[0].css('strong.location-link')[0].text.strip

            if el.css('.time-block > span.event-time.dtstart').count.positive?
              event.start = Time.zone.parse(el.css(".time-block']")[0].css('span.event-time.dtstart')[0].css('time')[0].get_attribute('datetime'))
              event.end = Time.zone.parse(el.css('.time-block')[0].css('span.end-time.dtend')[0].css('time')[0].get_attribute('datetime'))
            else
              event.start = Time.zone.parse(el.css('.time-block')[0].css('span.mc-start-date.dtstart')[0].get_attribute('content'))
              event.end = if el.css('.time-block')[0].css('span.event-time.dtend').count.positive?
                            Time.zone.parse(el.css('.time-block')[0].css('span.event-time.dtend')[0].text.strip)
                          else
                            event.start
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
