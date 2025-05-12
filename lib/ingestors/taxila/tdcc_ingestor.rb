require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  module Taxila
    class TdccIngestor < Ingestor
      def self.config
        {
          key: 'tdcc_event',
          title: 'TDCC Events API',
          category: :events
        }
      end

      def read(url)
        begin
          process_tdcc(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_tdcc(url)
        event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css("article .archive__grid .card__main")
        event_page.each do |event_data|
          event = OpenStruct.new

          event.title = event_data.css("h2.card__title a")[0].text.strip
          event.url = event_data.css("h2.card__title a")[0].get_attribute('href').strip
          event.venue = event_data.css("dl.meta-list svg.icon--marker")[0]&.parent&.text&.strip || 'Online'
          time_str = event_data.css("dl.meta-list svg.icon--calendar")[0].parent.text.strip
          split_time_str = time_str.split(' — ')
          event.start = Time.zone.parse(split_time_str[0])
          if split_time_str[1].split(' ').length == 1
            a = split_time_str[0].split(' ')
            b = split_time_str[1]
            event.end = Time.zone.parse([a[0], a[1], b].join(' '))
          elsif split_time_str[1].split(' ').length == 3
            event.end = Time.zone.parse(split_time_str[1])
          elsif split_time_str[1].split(' ').length == 2
            event.end = Time.zone.parse(split_time_str[1])
          end

          event_page2 = Nokogiri::HTML5.parse(open_url(event.url.to_s, raise: true)).css('article')[0]
          sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/tdcc.yml')
          event.description = recursive_description_func(event_page2.css("div[class='entry__inner padded container']"))

          event.source = 'TDCC'
          event.timezone = 'Amsterdam'
          event.set_default_times
          # site does not give year explicitly, assume that events are removed from site within week after event ends
          if event.end < Time.now - 1.week
            event.start += 1.year
            event.end += 1.year
          end

          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
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
