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
    # msg = call(content)['message']
    # res = get_first_json_from_string(msg)
    res = {
      title: "Open Hour SSH: Live Q&A on Monday",
      organizer: "Data Archive Netherlands (DANS)",
      description: "Get all your questions answered during Open Hour for the SSH community. A live Q&A every Monday morning. Meet us at the Open Hour every Monday from 10:00 to 11:00 CEST for the Social Sciences and Humanities (SSH) community. The Open Hour is a Q&A on Open Science, data storage and Research Data Management. Register here for the Open Hour and send in your question(s).",
      start: "2024-06-03T10:00:00+02:00",
      end: "2024-06-03T11:00:00+02:00",
      venue: "Online",
      keywords: ["natural & engineering sciences", "humanities & social sciences", "life sciences"],
      target_audience: ["researchers", "research support staff", "bachelor & master students", "PhD candidates", "teaching staff", "other"],
      open_science: ["open software", "FAIR data", "Open Access"],
      visible: true,
      url: "https://dans.knaw.nl/en/agenda/open-hour-ssh-live-qa-on-monday-2/",
      source: "LLM",
      timezone: "Amsterdam"
    }.to_json
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
  char_dict = {}
  char_dict['{'] = 0
  char_dict['}'] = 0
  start_end = [0, 0]
  res = msg
  msg.split('').each_with_index do |char, idx|
    next unless '{}'.include?(char)

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
