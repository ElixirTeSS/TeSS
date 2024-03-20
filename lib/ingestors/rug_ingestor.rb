# frozen_string_literal: true

require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class RugIngestor < Ingestor
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
      sleep(1) unless Rails.env.test? && File.exist?('test/vcr_cassettes/ingestors/rug.yml')
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css("div[class='rug-mb']")[0].css("div[itemtype='https://schema.org/Event']")
      event_page.each do |event_data|
        event = OpenStruct.new

        event.url = event_data.css("meta[itemprop='url']")[0].get_attribute('content')
        event.venue = event_data.css("meta[itemprop='location']")[0].get_attribute('content')
        event.title = event_data.css("meta[itemprop='name']")[0].get_attribute('content')
        event.start = Time.zone.parse(event_data.css("meta[itemprop='startDate']")[0].get_attribute('content').split('+').first)
        event.end = Time.zone.parse(event_data.css("meta[itemprop='endDate']")[0].get_attribute('content').split('+').first)

        event_page2 = Nokogiri::HTML5.parse(open_url(event.url.to_s, raise: true)).css("div[id='main']")[0].css("div[itemtype='https://schema.org/Event']")[0]
        sleep(1) unless Rails.env.test? && File.exist?('test/vcr_cassettes/ingestors/rug.yml')

        event.description = event_page2.css("div[class='rug-clearfix rug-theme--content rug-mb']")[0].css('p')[0].text

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
