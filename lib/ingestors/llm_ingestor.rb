require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class LlmIngestor < Ingestor
    def self.config
      {
        key: 'llm_event',
        title: 'LLM Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_llm(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_llm(_url)
      puts 'please provide child class'
    end

    def get_event_from_css(url, event_page) # rubocop:disable Metrics
      event_page.css('script, link').each { |node| node.remove }
      event_page = event_page.text.squeeze(" \n").squeeze("\n").squeeze("\t").squeeze(' ')
      llm_service_hash = {
        chatgpt: Llm::ChatgptService,
        willma: Llm::WillmaService
      }
      llm_service_class = llm_service_hash.fetch(TeSS::Config.llm_scraper['model'].to_sym, nil)
      return unless llm_service_class

      begin
        llm_service = llm_service_class.new
        event = OpenStruct.new
        event = llm_service.scrape_func(event, event_page)
        event = llm_service.post_process_func(event)
        event.url = url
        event.source = 'LLM'
        event.timezone = 'Amsterdam'
        a = Time.parse(event.start)
        event.start = Time.new(a.year, a.month, a.day, a.hour, a.min, a.sec, '+00:00')
        a = Time.parse(event.end)
        event.end = Time.new(a.year, a.month, a.day, a.hour, a.min, a.sec, '+00:00')
        event.set_default_times
        event.nonsense_attr = 'nonsense'
        event = OpenStruct.new(event.to_h.select { |key, _| (Event.attribute_names + [:online]).map(&:to_sym).include?(key) })
        add_event(event)
      rescue Exception => e
        puts e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
