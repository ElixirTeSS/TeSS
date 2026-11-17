# frozen_string_literal: true

require 'ostruct'
require_relative '../../app/scrapers/egi_scraper'

module Ingestors
  class EgiIngestor < Ingestor
    def self.config
      {
        key: 'egi',
        title: 'EGI Trainings and Webinars',
        category: :events,
        user_agent: 'TeSS EGI scraper'
      }
    end

    def read(source_url)
      response = open_url(source_url, raise: true)
      html = response.read
      scraper = EgiScraper.new(html)

      events = scraper.events
      Rails.logger.info("Training *Events* returned: #{events.length}")

      events.each do |event|
        Rails.logger.info("#{event[:title].inspect}")
        add_event(OpenStruct.new(event))
      end
    rescue StandardError => e
      Rails.logger.error("[EGI ingestor] #{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace&.any?

      @messages << "EGI ingestion failed: #{e.message}"
    end
  end
end
