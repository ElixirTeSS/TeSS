# frozen_string_literal: true

# Module for LLM based scraping and post processing
module Llm
  # Base class for LLM scraping and post processing
  class Service
    def initialize
      raise NotImplementedError
    end

    def llm_interaction_attributes
      {
        scrape_or_process: @scrape_or_process,
        model: @params[:model],
        prompt: @prompt,
        input: @input,
        output: @output,
        needs_processing: false
      }
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
      @prompt = File.read('lib/llm/llm_prompts/llm_scrape_prompt.txt')
      @input = event_page
      content = @prompt.gsub('*replace_with_event_page*', event_page)
      @output = run(content)
      @output
    end

    def process(event)
      @scrape_or_process = 'process'
      event_json = JSON.generate(event.to_json)
      @prompt = File.read('lib/llm/llm_prompts/llm_process_prompt.txt')
      @input = event_json
      content = @prompt.gsub('*replace_with_event*', event_json)
      @output = run(content)
      @output
    end

    def scrape_func(event, event_page)
      response = scrape(event_page)
      event = unload_json(event, response)
      event.llm_interaction_attributes = llm_interaction_attributes
      event
    end

    def post_process_func(event)
      response = process(event)
      event = unload_json(event, response)
      event.llm_interaction_attributes = llm_interaction_attributes
      event
    end

    def run(_content)
      raise NotImplementedError
    end

    def call(_prompt)
      raise NotImplementedError
    end
  end
end
