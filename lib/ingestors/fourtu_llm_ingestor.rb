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
  end
end
