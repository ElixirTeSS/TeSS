require 'icalendar'
require 'nokogiri'
require 'open-uri'
require 'tzinfo'

module Ingestors
  module Pantraining
    class LaserlabEventIngestor < Ingestor
      def self.config
        {
          key: 'laserlab_event',
          title: 'Laserlab Events',
          category: :events
        }
      end

      def read(url)
        @verbose = false
        scrape_laserlab_events(url)
      end

      scrape_laserlab_events(url)
      html = get_html_from_url(url)
    end
  end
end
