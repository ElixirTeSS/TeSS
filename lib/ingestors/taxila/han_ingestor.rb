require 'csv'
require 'nokogiri'

module Ingestors
  module Taxila
    class HanIngestor < Ingestor
      DATE_REGEXP = /\b\d{1,2}\s+(?:januari|februari|maart|april|mei|juni|juli|augustus|september|oktober|november|december)\s+\d{4}\b/i
      VENUE_REGEXP = /\bHAN in ([^.]+)/i

      def self.config
        {
          key: 'han_event',
          title: 'HAN Events API',
          category: :events
        }
      end

      def read(url)
        begin
          process_han(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_han(_url)
        url = 'https://www.han.nl/studeren/scholing-voor-werkenden/laboratorium/'

        event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('#content > .section--cards-skinny > .section-wrapper > .section__content > .cards-skinny > .cards-skinny-wrapper > .cards-skinny__item > .card-skinny > .card-skinny__content')
        event_page.each_with_index do |el, _idx|
          event = OpenStruct.new
          event.title = el.css('.card-skinny__content__title').first.text
          href = el.css('.card-skinny__content__buttons > .buttons > .buttons__button > a').first.get_attribute('href')
          event.url = href.start_with?('http') ? href : "https://www.han.nl#{href}"
          event.description = el.css('.card-skinny__content__body').first.text

          sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/han.yml')
          event_page2 = Nokogiri::HTML5.parse(open_url(event.url.to_s, raise: true))

          details_text = extract_details_text(event_page2)

          start_str = details_text[DATE_REGEXP]
          raise "no date found for #{event.url}" unless start_str

          event.start = Time.zone.parse(convert_months(start_str))
          event.end = event.start
          event.set_default_times

          venue_match = details_text.match(VENUE_REGEXP)
          event.venue = venue_match[1].strip if venue_match

          event.source = "HAN"
          event.timezone = 'Amsterdam'

          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end

      def extract_details_text(page)
        section = page.css('.collapsible').find do |collapsible|
          header = collapsible.css('.collapsible__header, button, h2, h3').first
          header && header.text =~ /tijden|startdat/i
        end
        scope = section ? section.css('.collapsible__content').first : page
        (scope || page).text.gsub(/\s+/, ' ').strip
      end

      def convert_months(my_str)
        {
          'januari': 'january',
          'februari': 'february',
          'maart': 'march',
          'april': 'april',
          'mei': 'may',
          'juni': 'june',
          'juli': 'july',
          'augustus': 'august',
          'september': 'september',
          'oktober': 'october',
          'november': 'november',
          'december': 'december',
        }.each do |key, value|
          my_str = my_str.gsub(key.to_s, value.to_s)
        end
        my_str
      end
    end
  end
end
