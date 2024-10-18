require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class RstIngestor < Ingestor
    def self.config
      {
        key: 'rst_material',
        title: 'RST Events API',
        category: :materials
      }
    end

    def read(url)
      begin
        process_rst(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_rst(_url)
      rst_url = 'https://www.esciencecenter.nl/training-materials/'

      material_page = Nokogiri::HTML5.parse(open_url(rst_url.to_s, raise: true)).css('h3.wp-block-heading')
      material_page.each_with_index do |el, _idx|
        material = OpenStruct.new
        material.title = el&.text
        parent = el.parent
        material.url = parent.css('.wp-block-buttons > .wp-block-button > a').first.get_attribute('href')
        material.description = rst_recursive_description_func(parent.css('p'))
        add_material(material)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end

def rst_recursive_description_func(css, res = '')
  if css.is_a?(Nokogiri::XML::Element)
    res += css.text.strip
  else
    css.each do |css2|
      res += rst_recursive_description_func(css2, res)
    end
  end
  res
end
