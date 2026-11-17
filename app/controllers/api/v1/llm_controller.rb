require 'net/http'
require 'uri'
require 'json'

class Api::V1::LlmController < ApplicationController
  before_action :authenticate_user!

  # ------------------------------------------------------------------
  # POST /api/v1/llm/chat
  # ------------------------------------------------------------------

  def chat
    tess       = params[:tess]
    tess_query = params[:tess_query]

    # --------------------------------------------------------------
    # Parsing incoming messages
    # --------------------------------------------------------------
    messages_params = parse_messages(params[:messages])

    if messages_params.empty?
      Rails.logger.info(
        "[LLM] Request rejected: 'messages' parameter missing or empty."
      )

      return render json: {
        error: 'Messages parameter is missing or empty.'
      }, status: :bad_request
    end

    messages = messages_params.map do |message|
      {
        'role' => message[:role] || message['role'],
        'content' => message[:content] || message['content']
      }
    end

    Rails.logger.info(
      '[LLM] Authenticated request: ' \
      "tess=#{tess.inspect} " \
      "tess_query=#{tess_query.inspect} " \
      "messages_count=#{messages.length}"
    )

    # --------------------------------------------------------------
    # Retrieve TeSS context
    # --------------------------------------------------------------
    Rails.logger.info('============================================')
    Rails.logger.info('[TeSS] Retrieving data ... (IN PROGRESS)    ')

    tess_data = retrieve_tess_data
    Rails.logger.info('============================================')
    Rails.logger.info('[TeSS] Data *RETRIEVED* from the server')
    Rails.logger.info(
      "Events=#{tess_data[:events].length}, " \
      "Materials=#{tess_data[:materials].length}, " \
      "Trainers=#{tess_data[:trainers].length}, " \
      "Providers=#{tess_data[:content_providers].length}"
    )

    # Parse tess_data in JSON format
    parsed_tess_data = tess_data.is_a?(String) ? JSON.parse(tess_data) : tess_data
    Rails.logger.info("\n#{JSON.pretty_generate(parsed_tess_data)}")

    # --------------------------------------------------------------
    # Forward request to EGI LLM service
    # --------------------------------------------------------------
    Rails.logger.info('===========================================')
    Rails.logger.info('[LLM] Retrieving data ... (IN PROGRESS)    ')

    llm_result = process_llm_request(
      messages: messages
    )

    llm_answer = llm_result.dig('choices', 0, 'message', 'content')
    if llm_answer.blank?
      Rails.logger.error('[LLM] Response did *NOT* containt an answer!')
      raise 'LLM response did *NOT* contain an answer'
    end

    Rails.logger.info('[LLM] Data *RETRIEVED* from the server')
    Rails.logger.info("\n #{JSON.pretty_generate(llm_result)}")

    Rails.logger.info('===========================================')
    Rails.logger.info('[TeSS + LLM] Merging the data collected ...')
    Rails.logger.info('===========================================')

    final_result = {
      'tess' => tess_data,
      'llm' => {
        'answer' => llm_answer
      }
    }

    # Rails.logger.info(final_result)
    Rails.logger.info("\n#{JSON.pretty_generate(final_result)}")

    # Rendering the combined results from TeSS and the EGI LLM server
    render json: final_result, status: :ok
  rescue ActionController::ParameterMissing => e
    Rails.logger.error(
      "[LLM] Parameter Error: #{e.message}"
    )

    render json: {
      error: e.message
    }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error(
      "[LLM] #{e.class}: #{e.message}"
    )

    Rails.logger.error(
      e.backtrace.first(10).join("\n")
    )

    render json: {
      error: 'LLM request failed'
    }, status: :internal_server_error
  end

  private

  def process_llm_request(messages:)
    llm_config = TeSS::Config.egi_llm || {}

    endpoint = llm_config[:server_url].presence ||
               raise('egi_llm.server_url is *NOT* configured in tess.yml')

    api_token = Rails.application.config.secrets.egi_llm_api_key.presence ||
                raise('egi_llm_api_key is *NOT* configured in secrets.yml')

    model = llm_config[:model].presence ||
            raise('egi_llm.model is *NOT* configured in tess.yml')

    timeout = llm_config.fetch(:timeout, 240).to_i

    uri = URI.parse(endpoint)
    outbound_request = Net::HTTP::Post.new(uri)

    outbound_request['Authorization'] = "Bearer #{api_token}"
    outbound_request['Content-Type'] = 'application/json'
    outbound_request['Accept'] = 'application/json'

    outbound_request.body = {
      messages: messages,
      model: model
    }.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    http.open_timeout = timeout
    http.read_timeout = timeout

    Rails.logger.info("[LLM] Sending outbound request to: #{endpoint}")
    Rails.logger.info(
      '[LLM] Request diagnostics: ' \
      "Method=#{outbound_request.method} " \
      "Host=#{uri.host} " \
      "Path=#{uri.path} " \
      "Body_bytes=#{outbound_request.body.bytesize} " \
      "Content_type=#{outbound_request['Content-Type']} " \
      "Accept=#{outbound_request['Accept']} " \
      "Authorization_present=#{!outbound_request['Authorization'].to_s.empty?}"
    )

    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    response = http.request(outbound_request)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at

    Rails.logger.info(
      "[LLM] Outbound HTTP status=#{response.code},
       Elapsed=#{elapsed.round(2)}s"
    )

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("[LLM] Outbound request FAILED with HTTP: #{response.code}")
      Rails.logger.error("[LLM] Outbound response body=#{response.body}")
      raise "LLM API request FAILED with HTTP: #{response.code}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    Rails.logger.error("[LLM] Invalid JSON returned by EGI LLM service: #{e.message}")

    raise 'Invalid JSON returned by LLM service'
  end

  # ------------------------------------------------------------------
  # TeSS data retrieval
  # ------------------------------------------------------------------
  def retrieve_tess_data
    query = params[:tess_query].presence || latest_user_message

    {
      events: fetch_tess_resource('events', query),
      materials: fetch_tess_resource('materials', query),
      trainers: fetch_tess_resource('trainers', query),
      content_providers: fetch_tess_resource('content_providers', query)
    }
  end

  # ------------------------------------------------------------------
  # Get latest user message
  # ------------------------------------------------------------------
  def latest_user_message
    params[:messages]
      &.reverse
      &.find do |message|
        message[:role] == 'user' ||
          message['role'] == 'user'
      end
      &.then do |message|
        message[:content] || message['content']
      end
      .to_s
  end

  # ------------------------------------------------------------------
  # Fetch TeSS resource
  # ------------------------------------------------------------------
  def fetch_tess_resource(resource_type, query)
    base_url = tess_base_url
    endpoint = "#{base_url}/#{resource_type}.json_api"

    Rails.logger.info(
      "[TeSS] endpoint=#{endpoint}"
    )

    params = {
      'page[size]' => 10
    }

    params['q'] = query.to_s.truncate(200) if query.present?

    params['include_expired'] = 'true' if resource_type == 'events'

    Rails.logger.info("[TeSS] Endpoint = #{endpoint} #{params.inspect}")

    response = tess_connection(base_url).get(
      "/#{resource_type}.json_api",
      params
    )

    unless response.success?
      Rails.logger.warn(
        "[TeSS] #{resource_type} request response" \
        "[HTTP] #{response.status}"
      )

      return []
    end

    data = JSON.parse(response.body)

    Rails.logger.info(
      "[TeSS] Parsed JSON class = #{data.class} " \
      "key = #{data.respond_to?(:keys) ? data.keys.inspect : 'n/a'}"
    )

    records = normalize_tess_response(data)

    Rails.logger.info("[TeSS] Normalized records count = #{records.length}")
    records.first(10)
  rescue JSON::ParserError => e
    Rails.logger.error("[TeSS] Invalid JSON response for #{resource_type}: #{e.message}")

    []
  rescue StandardError => e
    Rails.logger.error(
      "[TeSS] Failed to retrieve #{resource_type}: " \
      "#{e.class}: #{e.message}"
    )

    []
  end

  # ------------------------------------------------------------------
  # TeSS connection
  # ------------------------------------------------------------------
  def tess_connection(base_url)
    Faraday.new(url: base_url) do |f|
      f.request :url_encoded
      f.options.timeout = 60
      f.options.open_timeout = 15
      f.adapter Faraday.default_adapter
    end
  end

  def tess_base_url
    TeSS::Config.base_url.to_s.chomp('/')
  end

  def normalize_tess_response(response)
    records =
      if response.is_a?(Hash)
        response['data'] || response['results'] || []
      elsif response.is_a?(Array)
        response
      else
        []
      end

    records.filter_map do |record|
      next unless record.is_a?(Hash)

      attributes = if record['attributes'].is_a?(Hash)
                     record['attributes']
                   else
                     record
                   end
      {
        id: record['id'] || attributes['id'],
        title: attributes['title'] || attributes['name'],
        description: attributes['description'] || attributes['summary'],
        url: attributes['url'] || attributes['html_url'],
        start_date: attributes['start'] ||
          attributes['start_date'] ||
          attributes['start_datetime'],
        end_date: attributes['end'] ||
          attributes['end_date'] ||
          attributes['end_datetime'],
        location: attributes['location'] || attributes['venue'],
        provider: attributes['content_provider'] ||
          attributes['provider']
      }.compact
    end
  end

  def parse_messages(raw_messages)
    return [] if raw_messages.blank? || !raw_messages.is_a?(Array)

    raw_messages.map do |msg|
      msg.is_a?(ActionController::Parameters) ? msg.permit(:role, :content).to_h : msg.slice('role', 'content')
    end
  end
end
