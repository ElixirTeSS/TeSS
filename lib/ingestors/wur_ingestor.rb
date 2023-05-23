# frozen_string_literal: true

require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class WurIngestor < Ingestor
    def self.config
      {
        key: 'wur_event',
        title: 'WUR Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_wur(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_wur(url)
      docs = Nokogiri::XML(open_url(url, raise: true)).xpath('//item')
      docs.each do |event_item|
        begin
          event = OpenStruct.new
          event.event_types = ['workshops_and_courses']
          event_item.element_children.each do |element|
            case element.name
            when 'title'
              event.title = element.text
            when 'link'
              event.url = element.text
              # only include events which have this in their path
              next unless event.url.include?('activity') || event.url.include?('Research-Results')
            when 'creator'
              # event.creator = element.text
              # no creator field. Not sure needs one
            when 'description'
              event.description = convert_description element.text
            when 'location'
              event.venue = element.text
              loc = element.text.split(',')
              event.city = loc.first.strip
              event.country = loc.last.strip
            when 'provider'
              event.organizer = element.text
            when 'startdate', 'courseDate'
              event.start = element.text.to_s
            when 'enddate', 'courseEndDate'
              event.end = element.text.to_s
            when 'latitude'
              event.latitude = element.text
            when 'longitude'
              event.longitude = element.text
            when 'pubDate'
              # Not really needed
            else
              # chuck away
            end
          end
        end
        # Now fetch the page to get the event date (until it is added to the RSS feed)
        unless event.start && !event.url.starts_with('https://')
          # should we do more against data exfiltration? URI.open is a known hazard
          page = Nokogiri::XML(open_url(event.url, raise: true))
          event.start, event.end = parse_dates(
            page.xpath('//th[.="Date"]').first&.parent&.xpath('td')&.last&.text&.strip, 'Amsterdam'
          )
          # in this case also grab the venue
          event.venue = page.xpath('//th[.="Venue"]').first&.parent&.xpath('td')&.last&.text
          sleep 1 unless Rails.env.test? && File.exist?('test/vcr_cassettes/ingestors/wur.yml')
        end

        event.set_default_times
        event.source = 'WUR'
        event.timezone = 'Amsterdam'

        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
