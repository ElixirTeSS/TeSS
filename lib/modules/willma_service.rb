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
    msg = call(content)['message']
    puts msg
    res = get_first_json_from_string(msg)
    puts res
    res
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

  request = case mode
            when 'post'
              Net::HTTP::Post.new(parsed_url.path)
            when 'get'
              Net::HTTP::Get.new(parsed_url.path)
            else
              Net::HTTP::Post.new(parsed_url.path)
            end

  header.each do |key, value|
    request[key] = value
  end
  request.set_form_data(data)
  request.body = data.to_json
  request.content_type = 'application/json'
  http.request(request)
end

def get_first_json_from_string(msg)
  char_dict = { '{': 0, '}': 0 }
  start_end = [0, 0]
  res = msg
  msg.split('').each_with_index do |char, idx|
    next unless char in '{}'

    char_dict[char] += 1
    if char == '{' && char_dict['{'] == 1
      start_end[0] = idx
    elsif char == '}' && char_dict['{'] == char_dict['}']
      start_end[1] = idx
      res = msg[start_end[0]..start_end[1]]
      break
    end
  end
  res
end
