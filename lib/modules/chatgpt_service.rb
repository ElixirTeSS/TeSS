# frozen_string_literal: true

class ChatgptService
  # require 'open-uri'
  # source = URI(url).open(&:read)
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

  def call(prompt)
    params = @params.merge(
      {
        messages: [{ role: 'user', content: prompt }]
      }
    )
    @client.chat(parameters: params)
  end

  def scrape(event_page, prompt)
    content = "Based on the following webpage describing a research event:\n\n#{event_page}\n\n #{prompt}"
    params = @params.merge(
      {
        response_format: { type: 'json_object' },
        messages: [{ role: 'user', content: }]
      }
    )
    @client.chat(parameters: params)
  end

  def beep
    file_name = 'beepboop.txt'
    content = File.read(file_name)

    params = @params.merge(
      {
        response_format: { type: 'json_object' },
        messages: [{ role: 'user', content: }]
      }
    )
    @client.chat(parameters: params)
  end

  class << self
    def call(message)
      new.call(message)
    end

    def scrape # rubocop:disable Metrics
      url = 'https://dans.knaw.nl/en/agenda/open-hour-ssh-live-qa-on-monday-2/'
      file_name = 'beepboop.txt'
      require 'open-uri'
      event_page = URI(url).open(&:read)
      doc = Nokogiri::HTML5.parse(event_page).css('body').css("div[id='nieuws_detail_row']")
      doc.css('script, link').each { |node| node.remove }
      event_page = doc.text.squeeze(" \n").squeeze("\n").squeeze("\t").squeeze(' ')
      prompt = File.read(file_name)
      response = new.scrape(event_page, prompt).dig('choices', 0, 'message', 'content')
      puts response
      JSON.parse(response)
    end

    def beep
      new.beep
    end
  end
end

# class ChatgptService
#   include HTTParty

#   attr_reader :api_url, :options, :body, :message

#   def initialize(message, model = 'gpt-3.5-turbo')
#     api_key = ENV.fetch('GPT_API_KEY', nil)
#     @options = {
#       headers: {
#         'Content-Type' => 'application/json',
#         'Authorization' => "Bearer #{api_key}"
#       }
#     }
#     @body = {
#       model:,
#       messages: [{ role: 'user', content: message }],
#       max_tokens: 50
#     }
#     @api_url = 'https://api.openai.com/v1/chat/completions'
#     @message = message
#   end

#   def call
#     response = HTTParty.post(api_url, body: body.to_json, headers: options[:headers], timeout: 10)
#     raise response['error']['message'] unless response.code == 200

#     response['choices'][0]['message']['content']
#   end

#   class << self
#     def call(message)
#       new(message).call
#     end
#   end
# end
