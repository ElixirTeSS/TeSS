# frozen_string_literal: true

class ChatgptService
  require 'openai'
  def initialize
    api_key = ENV.fetch('GPT_API_KEY', nil)
    @client = OpenAI::Client.new(access_token: api_key)
    @params = {
      # max_tokens: 50,
      model: 'gpt-3.5-turbo-1106',
      temperature: 0.7
    }
  end

  def run(content)
    beep = content
    params = @params.merge(
      {
        response_format: { type: 'json_object' },
        messages: [{ role: 'user', content: beep }]
      }
    )
    @client.chat(parameters: params)
  end

  def call(prompt)
    params = @params.merge(
      {
        messages: [{ role: 'user', content: prompt }]
      }
    )
    @client.chat(parameters: params)
  end

  def scrape(event_page)
    content = File.read('llm_scrape_prompt.txt')
                  .gsub('*replace_with_event_page*', event_page)
    run(content)
  end

  def process(event, collections)
    event_attrs = %i[title description venue start end keywords target_audience]
    collection_attrs = %i[title description keywords]
    event_json = JSON.generate(event.to_json(only: event_attrs))
    collections_json = JSON.generate(collections.map { |col| [col.id, col.to_json(only: collection_attrs)] }.to_h)
    content = File.read('llm_process_prompt.txt')
                  .gsub('*replace_with_event*', event_json)
                  .gsub('*replace_with_collections*', collections_json)
    run(content)
  end

  class << self
    def call(message)
      new.call(message)
    end

    def scrape # rubocop:disable Metrics
      url = 'https://dans.knaw.nl/en/agenda/open-hour-ssh-live-qa-on-monday-2/'
      require 'open-uri'
      event_page = URI(url).open(&:read)
      doc = Nokogiri::HTML5.parse(event_page).css('body').css("div[id='nieuws_detail_row']")
      doc.css('script, link').each { |node| node.remove }
      event_page = doc.text.squeeze(" \n").squeeze("\n").squeeze("\t").squeeze(' ')
      response = new.scrape(event_page).dig('choices', 0, 'message', 'content')
      puts response
      JSON.parse(response)
    end

    def process
      event_json = ChatgptService.scrape
      event = Event.new(event_json)
      collections = [
        Collection.new(title: 'Python stuff', description: 'Anything concerning the python programming language', keywords: %w[python programming IT]),
        Collection.new(title: 'Open hours on mondays', description: 'All open hours that happen on the first day of the week', keywords: %w[Monday questions])
      ]
      response = new.process(event, collections).dig('choices', 0, 'message', 'content')
      puts response
      JSON.parse(response)
    end
  end
end
