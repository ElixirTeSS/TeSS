require 'sitemap-parser'

module Ingestors
  class Ingestor
    include EventIngestion
    include MaterialIngestion

    def initialize
      @messages = []
      @stats = {
        events: { processed: 0, added: 0, updated: 0, rejected: 0 },
        materials: { processed: 0, added: 0, updated: 0, rejected: 0 }
      }
      @token = ''
      @events = []
      @materials = []
    end

    # accessor methods
    attr_reader :messages, :stats, :events, :materials
    attr_accessor :token

    def self.config
      raise NotImplementedError
    end

    def config
      self.class.config
    end

    # methods
    def read(_url)
      raise NotImplementedError
    end

    def write(user, provider)
      write_events(user, provider)
      @messages << "events processed[#{stats[:events][:processed]}] added[#{stats[:events][:added]}] updated[#{stats[:events][:updated]}] rejected[#{stats[:events][:rejected]}]"
      write_materials(user, provider)
      @messages << "materials processed[#{stats[:materials][:processed]}] added[#{stats[:materials][:added]}] updated[#{stats[:materials][:updated]}] rejected[#{stats[:materials][:rejected]}]"
    end

    def open_url(url)
      options = {
        redirect: false, # We're doing redirects manually below, since open-uri can't handle http -> https redirection
        read_timeout: 5
      }
      options[:ssl_verify_mode] = config[:ssl_verify_mode] if config.key?(:ssl_verify_mode)
      redirect_attempts = 5
      begin
        URI.open(url, options)
      rescue OpenURI::HTTPRedirect => e
        url = e.uri.to_s
        retry if (redirect_attempts -= 1) > 0
        raise e
      rescue OpenURI::HTTPError => e
        @messages << "Couldn't open URL #{url}: #{e}"
        return nil
      end
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

    def ingested
      @events.count + @materials.count
    end

    def processed
      @stats.values.sum { |s| s[:processed] }
    end

    def added
      @stats.values.sum { |s| s[:added] }
    end

    def updated
      @stats.values.sum { |s| s[:updated] }
    end

    def rejected
      @stats.values.sum { |s| s[:rejected] }
    end
  end
end
