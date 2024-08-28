require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class LcrdmIngestor < Ingestor
    def self.config
      {
        key: 'lcrdm_event',
        title: 'LCRDM Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_lcrdm(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_lcrdm(url)
      sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/lcrdm.yml')
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css("div[class='archive__content grid']")[0].css("div[class='post-item__inner']")
      event_page.each do |event_data|
        event = OpenStruct.new

        event.title = event_data.css("h2[class='post-item__title h5']")[0].css('a')[0].text.strip
        event.url = event_data.css("h2[class='post-item__title h5']")[0].css('a')[0].get_attribute('href').strip
        event.venue = event_data.css("ul[class='post-item__meta']")[0].css("svg[class='icon icon--marker ']")[0].parent.text.strip

        time_str = event_data.css("ul[class='post-item__meta']")[0].css("svg[class='icon icon--calendar ']")[0].parent.text.strip
        split_time_str = time_str.split(' — ')
        event.start = Time.zone.parse(split_time_str[0])
        if split_time_str[1].split(' ').length == 1
          a = split_time_str[0].split(' ')
          b = split_time_str[1]
          event.end = Time.zone.parse([a[0], a[1], b].join(' '))
        elsif split_time_str[1].split(' ').length == 3
          event.end = Time.zone.parse(split_time_str[1])
        end

        event_page2 = Nokogiri::HTML5.parse(open_url(event.url.to_s, raise: true)).css("main[id='main-content']")[0].css("div[class='entry__inner padded container']")
        sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/lcrdm.yml')
        event.description = recursive_description_func(event_page2)

        event.source = 'LCRDM'
        event.timezone = 'Amsterdam'
        event.set_default_times

        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end

def recursive_description_func(css, res = '')
  if css.length == 1
    res += css.text.strip
  else
    css.each do |css2|
      res += recursive_description_func(css2, res)
    end
  end
  res
end
