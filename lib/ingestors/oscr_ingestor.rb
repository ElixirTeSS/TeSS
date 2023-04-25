require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class RUGIngestor < Ingestor
    def self.config
      {
        key: 'rug_event',
        title: 'RUG Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_rug(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_rug(url)
      unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/rug.yml')
        sleep(1)
      end
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css("div[class='rug-mb']")[0].css("div[itemtype='https://schema.org/Event']")
      event_page.each do |event_data|
        event = OpenStruct.new

        event.url = event_page.querySelector("meta[itemprop='url']").getAttribute('content')
        event.location = event_page.querySelector("meta[itemprop='location']").getAttribute('content')
        event.title = event_page.querySelector("meta[itemprop='name']").getAttribute('content')
        event.start = event_page.querySelector("meta[itemprop='startDate']").getAttribute('content')
        event.end = event_page.querySelector("meta[itemprop='endDate']").getAttribute('content')

        event.source = 'RUG'
        event.timezone = 'Amsterdam'
        event.set_default_times

        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
