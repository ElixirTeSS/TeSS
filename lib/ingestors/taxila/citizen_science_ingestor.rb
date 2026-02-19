# frozen_string_literal: true

require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  module Taxila
    class CitizenScienceIngestor < Ingestor
      def self.config
        {
          key: 'citizen_science_event',
          title: 'CitizenScience Events API',
          category: :events
        }
      end

      def read(url)
        begin
          process_citizen_science_events(url)
          process_citizen_science_materials(url)
        rescue Exception => e
          @messages << "#{self.class.name} failed with: #{e.message}"
        end

        # finished
        nil
      end

      private

      def process_citizen_science_events(_url)
        citizen_science_url = 'https://citizenscience.nl/events/'
        overview_page = Nokogiri::HTML5.parse(open_url(citizen_science_url.to_s, raise: true))
                                       .at_xpath("//h1[normalize-space(.)='Aankomende evenementen']")
                                       &.ancestors('.container')&.first
                                       &.css('.row')&.first
                                       &.css('.card')

        overview_page.each_with_index do |el, _idx|
          event = OpenStruct.new
          event.url = el.css('a.btn').first['href']
          event.title = el.css('p.project-name').text.strip
          date_str = el.css('.fa-calendar').first.parent.text.strip
          mapped_date_str = citizen_science_month_mapping(date_str)
          event.start = DateTime.parse(mapped_date_str)
          event.set_default_times
          event.venue = el.css('.fa-map-marker-alt').first.parent.text.strip
          event.description = el.css("div.half-content > p:not([style*='display: none']):not([hidden])").first.text.strip
          event.source = 'CitizenScience'
          event.timezone = 'Amsterdam'
          add_event(event)
        rescue Exception => e
          @messages << "Extract event fields failed with: #{e.message}"
        end
      end

      def process_citizen_science_materials(_url)
        urls = [
          'https://citizenscience.nl/resources',
          'https://citizenscience.nl/training_resources'
        ]

        urls.each do |citizen_science_url|
          3.times do |i|
            new_url = "#{citizen_science_url}?page=#{i + 1}"
            sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/citizen_science.yml')
            overview_page = Nokogiri::HTML5.parse(open_url(new_url.to_s, raise: true))
                                           .css('.project-card')

            overview_page.each_with_index do |el, _idx|
              material = OpenStruct.new
              material.url = "https://www.citizenscience.nl#{el.css('h3.project-name').first.parent['href']}"
              material.title = el.css('h3.project-name').first.text.strip
              material.description = el.css(".project-description").first.text.strip
              add_material(material)
            rescue Exception => e
              @messages << "Extract material fields failed with: #{e.message}"
            end
          end
        end
      end
    end
  end
end

def citizen_science_month_mapping(str)
  mapping = [
    %w[Mrt Mar],
    %w[Mei May],
    %w[Okt Oct]
  ]
  mapping.each do |dutch, english|
    str = str.gsub(dutch, english)
  end
  str
end
