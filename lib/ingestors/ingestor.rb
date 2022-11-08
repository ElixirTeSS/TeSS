module Ingestors
  class Ingestor
    include EventIngestion
    include MaterialIngestion

    def initialize
      @messages = []
      @ingested = 0
      @processed = 0
      @added = 0
      @updated = 0
      @rejected = 0
      @token = ''
      @events = []
      @materials = []
    end

    # accessor methods
    attr_reader :messages
    attr_reader :ingested, :processed, :added, :updated, :rejected
    attr_accessor :token

    def self.config
      raise NotImplementedError
    end

    # methods
    def read(_url)
      raise NotImplementedError
    end

    def write(user, provider)
      write_events(user, provider)
      write_materials(user, provider)
    end

    def convert_description(input)
      return input if input.nil?
      return input if input == ActionController::Base.helpers.strip_tags(input)

      ReverseMarkdown.convert(input, tag_border: '').strip
    end

    def get_json_response(url, accept_params = 'application/json')
      response = RestClient::Request.new(method: :get,
                                         url: CGI.unescape_html(url),
                                         verify_ssl: false,
                                         headers: { accept: accept_params }).execute
      # check response
      raise "invalid response code: #{response.code}" unless response.code == 200

      JSON.parse(response.to_str)
    end
  end
end
