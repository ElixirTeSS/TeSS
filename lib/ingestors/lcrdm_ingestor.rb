require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class LCRDMIngestor < Ingestor
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
      unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/lcrdm.yml')
        sleep(1)
      end
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css("div[class='archive__content grid']")[0].css("div[class='column span-4-sm span-8-md span-6-lg']")
      event_page.each do |event_data|
        event = OpenStruct.new

        event.title = event_page.css("h2[class='post-item__title h5']").css("a").text
        event.url = event_page.css("h2[class='post-item__title h5']").css("a")['href']

        event.location = event_page.css("ul[class='post-item__meta']").css("li").first.text
        time_str = event_page.css("ul[class='post-item__meta']").css("li").last.text
        split_time_str = time_str.split('-')
        event.start = split_time_str[0].to_time
        if [1].split(' ').length == 1
          a = split_time_str[0].split(' ')
          b = split_time_str[1]
          event.end =  [a[0], a[1], b].join(' ').to_time
        elsif split_time_str[1].split(' ').length == 3
          event.end = split_time_str[1].to_time
        end

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
