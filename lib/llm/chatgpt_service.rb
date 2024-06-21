# frozen_string_literal: true

# Module for LLM based scraping and post processing
module Llm
  # ChatGPT based LLM scraping and post processing
  class ChatgptService < Service
    require 'openai'
    def initialize
      api_key = Rails.application.secrets&.gpt_api_key
      @client = OpenAI::Client.new(access_token: api_key)
      @params = {
        # max_tokens: 50,
        # model: 'gpt-3.5-turbo-1106',
        model: TeSS::Config.llm_scraper['model_version'],
        temperature: 0.7
      }
    end

    def run(content)
      call(content).dig('choices', 0, 'message', 'content')
    end

    def call(prompt)
      params = @params.merge(
        {
          messages: [{ role: 'user', content: prompt }]
        }
      )
      @client.chat(parameters: params)
    end
  end
end
