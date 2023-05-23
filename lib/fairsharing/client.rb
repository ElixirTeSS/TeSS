# frozen_string_literal: true

module Fairsharing
  class Client
    REDIS_KEY = 'fairsharing:token'

    def initialize(base = 'https://api.fairsharing.org')
      @base = RestClient::Resource.new(base)
    end

    def search(query:, type: 'any', page: 1, per_page: 25)
      path = '/search/fairsharing_records'
      params = {
        'q': query,
        'page[number]': page.to_i,
        'page[size]': per_page.to_i
      }
      params['fairsharing_registry'] = type unless type.nil? || type == 'any'

      response = authenticated_request(path, method: :post, body: '', params: params)
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
      redis = Redis.new(url: TeSS::Config.redis_url)
      expiry = redis.hget(REDIS_KEY, 'expiry')
      t = redis.hget(REDIS_KEY, 'token')
      if t && expiry && !Time.zone.at(expiry.to_i).past?
        t
      else
        response = get_token
        if response.code == 200
          payload = JSON.parse(response.body)
          redis.hset(REDIS_KEY, 'token', payload['jwt'])
          redis.hset(REDIS_KEY, 'expiry', payload['expiry'])
          payload['jwt']
        end
      end
    end

    private

    def authenticated_request(path, method: :get, body: nil, **opts)
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
