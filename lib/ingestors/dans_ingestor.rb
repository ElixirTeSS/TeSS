require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class DansIngestor < Ingestor
    def self.config
      {
        key: 'dans_event',
        title: 'Dans Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_dans(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_dans(url)
      4.times.each do |i| # always check the first 4 pages, # of pages could be increased if needed
        unless rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/dans.yml')
          sleep(1)
        end
        event_page = Nokogiri::HTML5.parse(open_url(url + i.to_s, raise: true)).css("div[id='nieuws_item_section']")
        event_page.each do |event_data|
          event = OpenStruct.new

          # dates
          dates = event_data.css("div[id='nieuws_image_date_row']").css('p').css('span')
          event.start = dates[0].children.to_s.to_time
          event.end = dates[1].children.to_s.to_time if dates.length == 2
          event.set_default_times

          data = event_data.css("div[id='nieuws_content_row']").css('div')[0].css('div')[0]
          event.title = convert_title data.css("div[id='agenda_titel']").css('h3')[0].children.to_s

          event.keywords = []
          data.css("div[id='cat_nieuws_item']").css('p').css('span').each do |key|
            value = key.children
            event.keywords << value unless value.nil?
          end
          data.css("div[id='tag_nieuws']").css('p').css('span').each do |key|
            value = key.children
            event.keywords << value unless value.nil?
          end

          event.description = data.css("p[class='dmach-acf-value dmach-acf-video-container']")[0].children.to_s

          event.url = data.css("a[id$='_link']")[0]['href'].to_s

          event.source = 'DANS'
          event.timezone = 'Amsterdam'

          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end
