# frozen_string_literal: true

class ChatgptService
  require 'openai'
  def initialize
    api_key = ENV.fetch('GPT_API_KEY', nil)
    @client = OpenAI::Client.new(access_token: api_key)
    @params = {
      # max_tokens: 50,
      # model: 'gpt-3.5-turbo-1106',
      model: 'gpt-4',
      temperature: 0.7
    }
  end

  def llm_object
    LlmObject.new(
      scrape_or_process: @scrape_or_process,
      model: @params[:model],
      prompt: @prompt,
      input: @input,
      output: @output
    )
  end

  def run(content)
    beep = content
    params = @params.merge(
      {
        # response_format: { type: 'json_object' },
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
    @scrape_or_process = 'scrape'
    @prompt = File.read('llm_scrape_prompt.txt')
    @input = event_page
    content = @prompt.gsub('*replace_with_event_page*', event_page)
    @output = run(content)
    @output
  end

  def process(event)
    @scrape_or_process = 'process'
    event_json = JSON.generate(event.to_json)
    @prompt = File.read('llm_process_prompt.txt')
    @input = event_json
    content = @prompt.gsub('*replace_with_event*', event_json)
    @output = run(content)
    @output
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
      response = new.process(event).dig('choices', 0, 'message', 'content')
      puts response
      JSON.parse(response)
    end
  end
end
