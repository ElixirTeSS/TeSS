# frozen_string_literal: true

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
      rst_url = 'https://researchsoftwaretraining.nl/resources/'
      material_page = Nokogiri::HTML5.parse(open_url(rst_url.to_s, raise: true)).css("div[class='inner_content cf']").first.css('p > a')
      material_page.each_with_index do |el, _idx|
        material = OpenStruct.new
        material.title = el&.text
        material.url = el&.get_attribute('href')
        material.description = material.title
        add_material(material)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
