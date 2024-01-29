require 'open-uri'
require 'csv'
require 'nokogiri'
require 'active_support/core_ext/hash'

module Ingestors
  class SurfIngestor < Ingestor
    def self.config
      {
        key: 'surf_event',
        title: 'Surf Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_surf(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_surf(url)
      Hash.from_xml(Nokogiri::XML(open_url(url, raise: true)).to_s)['urlset']['url'].each do |event_page|
        next unless event_page['loc'].include?('/en/agenda/')

        sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/surf.yml')
        data_json = Nokogiri::HTML5.parse(open_url(event_page['loc'], raise: false))&.css('script[type="application/ld+json"]')
        next unless data_json.present? && data_json.length > 0

        data = JSON.parse(data_json.first.text)
        begin
          # create new event
          event = OpenStruct.new

          # extract event details from
          attr = data['@graph'].first
          event.title = convert_title attr['name']
          event.url = attr['url']&.strip
          event.description = convert_description attr['description']
          event.start = attr['startDate']
          event.end = attr['endDate']
          event.set_default_times
          event.venue = if attr['location'].is_a?(Array)
                          attr['location'].join(' - ')
                        else
                          attr['location']
                        end
          event.source = 'SURF'
          event.online = true
          event.timezone = 'Amsterdam'

          # add event to events array
          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end
