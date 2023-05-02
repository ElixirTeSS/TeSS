require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class OsceIngestor < Ingestor
    def self.config
      {
        key: 'osce_event',
        title: 'OSCE Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_osce(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_osce(url)
      unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/osce.yml')
        sleep(1)
      end
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css("div[class='hJDwNd-AhqUyc-wNfPc Ft7HRd-AhqUyc-wNfPc purZT-AhqUyc-II5mzb ZcASvf-AhqUyc-II5mzb pSzOP-AhqUyc-wNfPc Ktthjf-AhqUyc-wNfPc JNdkSc SQVYQc yYI8W HQwdzb']")
      event_page.each do |event_data|
        event = OpenStruct.new

        event.title = event_data.css("span[class='C9DxTc aw5Odc ']")[0].text
        event.url = event_data.css("span[class='C9DxTc aw5Odc ']")[0].text
        event.description = event_data.css("span[class='C9DxTc aw5Odc ']")[0].text

        event.venue = event_data.css("span[class='C9DxTc aw5Odc ']")[0].text
        event.start = event_data.css("span[class='C9DxTc aw5Odc ']")[0].text
        event.end = event_data.css("span[class='C9DxTc aw5Odc ']")[0].text

        event.source = 'OSCE'
        event.timezone = 'Amsterdam'
        event.set_default_times

        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
