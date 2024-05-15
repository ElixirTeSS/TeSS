# frozen_string_literal: true

class WillmaService < LlmService
  require 'openai'
  def initialize
    model_name = TeSS::Config.llm_scraper['model_version']
    model_url = 'https://willma.soil.surf.nl/api/models'
    parsed_response = JSON.parse(do_request(model_url, 'get', {}).body)
    model_id = parsed_response.select { |i| i['name'] == model_name }.first['id']
    @params = {
      model: model_name,
      sequence_id: model_id,
      temperature: 0.7
    }
  end

  def run(content)
    call(content)['message']
  end

  def call(prompt)
    data = {
      'sequence_id': @params[:sequence_id],
      'input': prompt
    }
    query_url = 'https://willma.soil.surf.nl/api/query'
    response = do_request(query_url, 'post', data)
    JSON.parse(response.body)
  end
end

def do_request(url, mode, data = {})
  header = {
    'Content-Type': 'application/json',
    'X-API-KEY': ENV.fetch('WILLMA_API_KEY')
  }

  parsed_url = URI.parse(url)
  http = Net::HTTP.new(parsed_url.host, parsed_url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER

  case mode
  when 'post'
    request = Net::HTTP::Post.new(parsed_url.path)
  when 'get'
    request = Net::HTTP::Get.new(parsed_url.path)
  else
    puts 'whoops'
    request = Net::HTTP::Post.new(parsed_url.path)
  end

  header.each do |key, value|
    request[key] = value
  end
  request.set_form_data(data)
  request.body = data.to_json
  request.content_type = 'application/json'
  http.request(request)
end
