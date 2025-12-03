require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  module Taxila
    class HanIngestor < Ingestor
      def self.config
        {
          key: 'han_material',
          title: 'HAN Materials API',
          category: :materials
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

        material_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('#content > .section--cards-skinny > .section-wrapper > .section__content > .cards-skinny > .cards-skinny-wrapper > .cards-skinny__item > .card-skinny > .card-skinny__content')
        material_page.each_with_index do |el, _idx|
          material = OpenStruct.new
          material.title = el.css('.card-skinny__content__title').first.text
          material.url = "https://www.han.nl#{el.css('.card-skinny__content__buttons > .buttons > .buttons__button > a').first.get_attribute('href')}"
          material.description = el.css('.card-skinny__content__body').first.text
          add_material(material)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end
