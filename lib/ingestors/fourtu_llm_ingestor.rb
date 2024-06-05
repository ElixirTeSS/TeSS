require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class FourtuLlmIngestor < LlmIngestor
    def self.config
      {
        key: '4tu_llm_event',
        title: '4TU LLM Events API',
        category: :events
      }
    end

    private

    def process_llm(_url)
      url = 'https://www.4tu.nl/en/agenda/'
      event_page = Nokogiri::HTML5.parse(open_url(url, raise: true)).css('.searchresults')[0].css('a.searchresult')
      event_page.each do |event_data|
        new_url = event_data['href']
        sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/4tu_llm.yml')
        new_event_page = Nokogiri::HTML5.parse(open_url(new_url, raise: true)).css('body').css('main, .page-header__content')
        get_event_from_css(new_url, new_event_page)
      end
    end
    # def process_llm(_url) # rubocop:disable Metrics
    #   url = 'https://www.rug.nl/wubbo-ockels-school/calendar/2024/'
    #   event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body').css("div[id='main']")[0].css("div[itemtype='https://schema.org/Event']")
    #   event_page.each do |event_data|
    #     new_url = event_data.css("meta[itemprop='url']")[0].get_attribute('content')
    #     sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
    #     new_event_page = Nokogiri::HTML5.parse(open_url(new_url.to_s, raise: true)).css('body').css("div[id='main']")[0].css("div[itemtype='https://schema.org/Event']")
    #     get_event_from_css(new_url, new_event_page)
    #   end
    # end
    # def process_llm(_url) # rubocop:disable Metrics
    #   url = 'https://www.nwo.nl/en/meetings'
    #   4.times.each do |i| # always check the first 4 pages, # of pages could be increased if needed
    #     sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
    #     event_page = Nokogiri::HTML5.parse(open_url("#{url}?page=#{i}", raise: true)).css('.overviewContent')[0].css('li.list-item').css('a')
    #     event_page.each do |event_data|
    #       new_url = "https://www.nwo.nl#{event_data['href']}"
    #       sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
    #       new_event_page = Nokogiri::HTML5.parse(open_url(new_url, raise: true)).css('body').css('main')[0].css('article')
    #       get_event_from_css(new_url, new_event_page)
    #     end
    #   end
    # end
    # def process_llm(_url)
    #   sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
    #   url = 'https://tdcc.nl/evenementen/teaming-up-across-domains/'
    #   event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body').css('article')[0]
    #   get_event_from_css(url, event_page)
    # end
    # def process_llm(_url)
    #   sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/llm.yml')
    #   url = 'https://dans.knaw.nl/en/agenda/open-hour-ssh-live-qa-on-monday-2/'
    #   event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body').css("div[id='nieuws_detail_row']")
    #   get_event_from_css(url, event_page)
    # end
  end
end
