require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  module Taxila
    class VuMaterialIngestor < Ingestor
      def self.config
        {
          key: 'vu_material',
          title: 'VU Materials API',
          category: :materials
        }
      end

      def read(url)
        begin
          process_vu(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_vu(url)
        headers = {
          'Host': 'vu.nl',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'api-version': '2020-06-30',
          'Content-Length': 396,
          'Origin': 'https://vu.nl',
          'Referer': 'https://vu.nl/en/education/phd-courses'
        }

        data = {
          "filter": "ItemType/any(c: search.in(c, 'Study', '|')) and ItemType/any(c: search.in(c, 'PhD', '|')) and Language eq 'EN'",
          "search": '*',
          "skip": 0,
          "top": 1000
        }

        url = URI.parse('https://vu.nl/api/search')
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = (url.scheme == 'https')
        request = Net::HTTP::Post.new('https://vu.nl/api/search')
        headers.each do |key, value|
          request[key] = value
        end
        request.set_form_data(data)
        request.body = data.to_json
        request.content_type = 'application/json'
        response = http.request(request)
        materials_json = JSON.parse(response.body)['value']

        # byebug
        materials_json.each do |val|
          material = OpenStruct.new
          material.title = val['Title']
          material.url = "https://vu.nl#{val['Url']}"
          material.description = val['IntroText']
          material.target_audience = parse_audience(material.description)
          add_material(material)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end
    end
  end
end
