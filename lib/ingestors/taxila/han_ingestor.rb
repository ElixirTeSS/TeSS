require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  module Taxila
    class HanIngestor < Ingestor
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
          event.url = "https://www.han.nl#{el.css('.card-skinny__content__buttons > .buttons > .buttons__button > a').first.get_attribute('href')}"
          event.description = el.css('.card-skinny__content__body').first.text

          sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/han.yml')
          event_page2 = Nokogiri::HTML5.parse(open_url(event.url.to_s, raise: true))
          start_str = event_page2.css("div[class='course-superhero__payoff__content']")[0].css('p > span.course-superhero__payoff__subtitle')[0].text
          start_str = convert_months(start_str)
          event.start = Time.zone.parse(start_str.split('en')[0].strip)
          event.end = event.start
          event.set_default_times

          course_details = event_page2.css("div[class='course-details__sidebar__item']")[0]
          venue_sub_css = course_details.css("span[class='nav-subswitch__title__label__sub']")[0]
          venue_super_css = venue_sub_css.parent.css("strong.nav-subswitch__title__label__super")[0]
          event.venue = "#{venue_super_css.text} #{venue_sub_css.text}"
          event.source = "HAN"
          event.timezone = 'Amsterdam'

          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
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