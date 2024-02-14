require 'open-uri'
require 'csv'
require 'nokogiri'

module Ingestors
  class GptIngestor < Ingestor
    def self.config
      {
        key: 'gpt_event',
        title: 'GPT Events API',
        category: :events
      }
    end

    def read(url)
      begin
        process_gpt(url)
      rescue Exception => e
        @messages << "#{self.class.name} failed with: #{e.message}"
      end

      # finished
      nil
    end

    private

    def process_gpt(_url)
      # dans HTML
      sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/gpt.yml')
      url = 'https://dans.knaw.nl/en/agenda/open-hour-ssh-live-qa-on-monday-2/'
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body').css("div[id='nieuws_detail_row']")
      beep_func(event_page)

      # nwo HTML
      sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/gpt.yml')
      url = 'https://www.nwo.nl/en/meetings'
      event_page = Nokogiri::HTML5.parse(open_url("#{url}?page=0", raise: true)).css('.overviewContent > .listing-cards > li.list-item')[3]
      beep_func(event_page)

      # rug HTML
      sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/gpt.yml')
      url = 'https://www.rug.nl/about-ug/latest-news/events/calendar/2023/phallus-tentoonstelling'
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body').css("div[class='rug-mb']")[0].css("div[itemtype='https://schema.org/Event']")
      beep_func(event_page)

      # tdcc HTML
      sleep(1) unless Rails.env.test? and File.exist?('test/vcr_cassettes/ingestors/gpt.yml')
      url = 'https://tdcc.nl/evenementen/teaming-up-across-domains/'
      event_page = Nokogiri::HTML5.parse(open_url(url.to_s, raise: true)).css('body').css('article')[0]
      beep_func(event_page)

      # json not necessary (SURF, UvA)
      # XML not necessary (wur)
    end

    def beep_func(event_page) # rubocop:disable Metrics
      prompt = File.read('beepboop.txt')
      event_page.css('script, link').each { |node| node.remove }
      event_page = event_page.text.squeeze(" \n").squeeze("\n").squeeze("\t").squeeze(' ')
      response = ChatgptService.new.scrape(event_page, prompt).dig('choices', 0, 'message', 'content')
      puts response
      response_json = JSON.parse(response)
      begin
        event = OpenStruct.new
        response_json.each_key do |key|
          event[key] = response_json[key]
        end
        event.source = 'GPT'
        event.timezone = 'Amsterdam'
        add_event(event)
      rescue Exception => e
        @messages << "Extract event fields failed with: #{e.message}"
      end
    end
  end
end
