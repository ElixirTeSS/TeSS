require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class CarpentriesIngestor < Ingestor
    CURRICULA_URL = 'https://feeds.carpentries.org/amy_curricula.json'

    def self.config
      {
        key: 'carpentries',
        title: 'Carpentries JSON Feed',
        category: :events
      }
    end

    def read(url)
      workshops = JSON.parse(open_url(url).read)
      workshops.each do |workshop|
        process_workshop(workshop)
      end
    end

    private

    def process_workshop(workshop)
      return if workshop['curriculum'].nil? || workshop['curriculum'] == 'unknown'
      event = OpenStruct.new
      event.url = workshop['url']
      event.start = Date.parse(workshop['start_date']) if workshop['start_date']
      event.end = Date.parse(workshop['end_date']) if workshop['end_date']
      event.latitude = workshop['latitude']
      event.longitude = workshop['longitude']
      curriculum = curricula[workshop['curriculum']]
      event.title = curriculum['name'] if curriculum
      tags = (workshop['tag_name']&.split(',') || []).map(&:strip)
      event.venue = workshop['venue']
      event.host_institutions = Array(workshop['host_name'])
      event.presence = :online if tags.delete('online') || event.venue.include?('online')
      begin
        country = IsoCountryCodes.find(workshop['country'])
        event.country = country.name
      rescue IsoCountryCodes::UnknownCodeError
      end

      @events << event
    end

    def curricula
      Rails.cache.fetch('carpentries-curricula', expires_in: 1.week) do
        json = URI.open(CURRICULA_URL).read
        hash = {}
        JSON.parse(json).each do |c|
          hash[c['slug']] = c
          hash[c['slug']]['name'] = 'Carpentries Mix & Match' if c['slug'] == 'mix-and-match'
        end
        hash
      end
    end
  end
end
