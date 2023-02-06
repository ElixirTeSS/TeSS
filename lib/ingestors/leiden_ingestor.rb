require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class LeidenIngestor < Ingestor
    def self.config
      {
        key: 'leiden_event',
        title: 'Leiden Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_leiden(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_leiden(url)
      4.times.each do |i| # always check the first 4 pages, # of pages could be increased if needed
        sleep(1)
        event_links = Nokogiri::HTML5.parse(open_url("#{url}?pageNumber=#{i+1}", raise: true)).css('#content > ul > li > a')
        return if event_links.empty?

        event_links.each do |event_link|
          event_url = "https://www.library.universiteitleiden.nl#{event_link.attributes['href']}"
          event_data = Nokogiri::HTML5.parse(open_url(event_url, raise: true))

          event = Event.new

          # dates
          event.title = convert_title event_data.css('#content h1').text
          event.timezone = 'Europe/Amsterdam'
          properties = event_data.css('dl.facts > dt')
          values = event_data.css('dl.facts > dd')
          date = '' # have a global variable here since it is reused in scanning the properties block
          properties.zip(values) do |property, value|
            case property.text.strip
            when 'Date'
              date = value.text.strip
              event.start, event.end = parse_dates(date)
            when 'Time'
              time = value.text.strip
              event.start, event.end = parse_dates("#{date} #{time}")
            when 'Address'
              lines = value.text.strip.split("\n")
              if lines.length > 2
                # if multi-line, use the first line for venue and get the city from the last line
                event.venue = lines.first.strip
                event.city = lines.last.gsub(/[0-9]{4} ?[a-zA-Z]{2}/, '')
              else
                # if it is a single line just use it as venue
                event.venue = lines.first.strip
              end
            when 'Room'
              if event.venue
                # skip the info for now
                #event.venue += " - #{value.text.strip}"
              else
                event.venue = value.text.strip
              end
            end
          end
          event.set_default_times

          event.keywords = []
          event.description = convert_description event_data.css('#content .indent').inner_html

          event.url = event_url
          # We could also extract the trainer name from the page, but there are two.
          # does TeSS support that?

          event.source = 'Universiteit Leiden'

          add_event(event)
          @ingested += 1
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message} for #{event_url}"
        end
      end
    end
  end
end
