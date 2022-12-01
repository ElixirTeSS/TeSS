module Fairsharing
  class Client
    class SearchResults < Array
      attr_accessor :page, :first_page, :prev_page, :next_page, :last_page

      def self.from_api_response(hash)
        results = new(hash['data'])
        hash['links'].each do |key, value|
          value = value&.split('?')&.last
          next unless value
          page_number = Rack::Utils.parse_nested_query(value).dig('page', 'number')&.to_i
          next unless page_number
          case key
          when 'self'
            results.page = page_number
          when 'first'
            results.first_page = page_number
          when 'prev'
            results.prev_page = page_number
          when 'next'
            results.next_page = page_number
          when 'last'
            results.last_page = page_number
          end
        end
        results
      end
    end

    REDIS_KEY = 'fairsharing:token'.freeze

    def initialize(base = 'https://api.fairsharing.org')
      @base = RestClient::Resource.new(base)
      @redis = Redis.new(url: TeSS::Config.redis_url)
    end

    def search(query:, type: 'any', page: 1, per_page: 25)
      path = "/search/fairsharing_records"
      params = {
        'q': query,
        'page[number]': page,
        'page[size]': per_page,
      }
      params['fairsharing_registry'] = type unless type.nil? || type == 'any'

      response = request(path, method: :post, body: '', params: params)
      SearchResults.from_api_response(JSON.parse(response.body))
    end

    def get_token(username = nil, password = nil)
      username ||= Rails.application.secrets.fairsharing&.dig(:username)
      password ||= Rails.application.secrets.fairsharing&.dig(:password)
      body = {
        'user': {
          'login': username,
          'password': password
        }
      }

      @base['/users/sign_in'].post(body.to_json, content_type: :json)
    end

    def token
      expiry = @redis.hget(REDIS_KEY, 'expiry')
      t = @redis.hget(REDIS_KEY, 'token')
      if t && expiry && !Time.at(expiry.to_i).past?
        t
      else
        response = get_token
        if response.code == 200
          payload = JSON.parse(response.body)
          @redis.hset(REDIS_KEY, 'token', payload['jwt'])
          @redis.hset(REDIS_KEY, 'expiry', payload['expiry'])
          return payload['jwt']
        end
      end
    end

    private

    def request(path, method: :get, body: nil, **opts)
      t = token

      headers = {
        accept: 'application/json',
        content_type: 'application/json',
        authorization: "Bearer #{t}"
      }

      args = []
      args << body if body
      args << opts.merge(headers)

      @base[path].send(method, *args)
    end
  end
end