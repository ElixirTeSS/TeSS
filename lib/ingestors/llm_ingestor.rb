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

    def scrape_dans
      sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
      url = 'https://dans.knaw.nl/en/agenda/open-hour-ssh-live-qa-on-monday-2/'
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body').css("div[id='nieuws_detail_row']")
      beep_func(url, event_page)
    end

    def scrape_nwo # rubocop:disable Metrics
      # sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
      # url = 'https://www.nwo.nl/en/meetings/dualis-event-in-utrecht'
      # event_page = Nokogiri::HTML5.parse(open_url(url, raise: true)).css('body').css('main')[0].css('article')
      # beep_func(url, event_page)
      url = 'https://www.nwo.nl/en/meetings'
      4.times.each do |i| # always check the first 4 pages, # of pages could be increased if needed
        sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
        event_page = Nokogiri::HTML5.parse(open_url("#{url}?page=#{i}", raise: true)).css('.overviewContent')[0].css('li.list-item').css('a')
        event_page.each do |event_data|
          new_url = "https://www.nwo.nl#{event_data['href']}"
          sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
          new_event_page = Nokogiri::HTML5.parse(open_url(new_url, raise: true)).css('body').css('main')[0].css('article')
          beep_func(new_url, new_event_page)
        end
      end
    end

    def scrape_rug # rubocop:disable Metrics
      # sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
      # url = 'https://www.rug.nl/about-ug/latest-news/events/calendar/2023/phallus-tentoonstelling'
      # event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body').css("div[id='main']")[0].css("div[itemtype='https://schema.org/Event']")
      # beep_func(url, event_page)
      url = 'https://www.rug.nl/wubbo-ockels-school/calendar/2024/'
      # event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body')[0].css("div[class='rug-mb']")[0].css("div[itemtype='https://schema.org/Event']")
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body').css("div[id='main']")[0].css("div[itemtype='https://schema.org/Event']")
      event_page.each do |event_data|
        new_url = event_data.css("meta[itemprop='url']")[0].get_attribute('content')
        sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
        new_event_page = Nokogiri::HTML5.parse(open_url(new_url.to_s, raise: true)).css('body').css("div[id='main']")[0].css("div[itemtype='https://schema.org/Event']")
        beep_func(new_url, new_event_page)
      end
    end

    def scrape_tdcc
      sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
      url = 'https://tdcc.nl/evenementen/teaming-up-across-domains/'
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body').css('article')[0]
      beep_func(url, event_page)
    end

    def process_llm(_url)
      scrape_dans
      scrape_nwo
      scrape_rug
      scrape_tdcc
      # json not necessary (SURF, UvA)
      # XML not necessary (wur)
    end

    def beep_func(url, event_page) # rubocop:disable Metrics
      event_page.css('script, link').each { |node| node.remove }
      event_page = event_page.text.squeeze(" \n").squeeze("\n").squeeze("\t").squeeze(' ')
      llm_service_hash = {
        chatgpt: ChatgptService,
        willma: WillmaService
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
        add_event(event)
      rescue Exception => e
        puts e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
