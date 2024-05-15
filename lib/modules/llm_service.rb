# frozen_string_literal: true

class LlmService
  def initialize
    puts 'please provide child class'
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

  def unload_json(event, response)
    response_json = JSON.parse(response)
    response_json.each_key do |key|
      event[key] = response_json[key]
    end
    event
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

  def scrape_func(event, event_page)
    response = scrape(event_page)
    puts response
    event = unload_json(event, response)
    event.llm_object = llm_object
    event
  end

  def post_process_func(event)
    response = process(event)
    puts response
    event = unload_json(event, response)
    event.llm_object = llm_object
    event
  end

  def run(_content)
    puts 'please provide child class'
  end

  def call(_prompt)
    puts 'please provide child class'
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
      response = new.scrape(event_page)
      puts response
      JSON.parse(response)
    end

    def process
      event_json = scrape
      puts 'hi'
      event = Event.new(event_json)
      response = new.process(event)
      puts response
      JSON.parse(response)
    end
  end
end
