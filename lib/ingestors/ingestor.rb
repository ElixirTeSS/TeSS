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
      write_resources(Event, @events, user, provider)
      @messages << stats_summary(:events)
      write_resources(Material, @materials, user, provider)
      @messages << stats_summary(:materials)
    end

    def stats_summary(type)
      "#{type} " << [:processed, :added, :updated, :rejected].map { |key| "#{key}[#{stats[type][key]}]" }.join(' ')
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
        nil
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

    private

    def set_resource_defaults(resource)
      resource.scraper_record = true
      resource.last_scraped = DateTime.now

      resource
    end

    def write_resources(type, resources, user, provider)
      resources.each_with_index do |resource, i|
        key = type.model_name.collection.to_sym
        @stats[key][:processed] += 1

        # check for matched events
        resource.user_id ||= user.id
        resource.content_provider_id ||= provider.id
        existing_resource = type.check_exists(resource.to_h)

        update = existing_resource && existing_resource.content_provider == provider
        resource = if update
                     update_resource(existing_resource, resource.to_h)
                   else
                     type.new(resource.to_h)
                   end

        resource = set_resource_defaults(resource)
        if resource.valid?
          resource.save!
          @stats[key][update ? :updated : :added] += 1
        else
          @stats[key][:rejected] += 1
          @messages << "#{type.model_name.human} failed validation: #{resource.title}"
          resource.errors.full_messages.each do |m|
            @messages << "Error: #{m}"
          end
        end

        resources[i] = resource
      end
    end

    def update_resource(existing_resource, fields)
      # overwrite unlocked attributes
      locked_fields = existing_resource.locked_fields

      fields.except(:content_provider_id, :user_id).each do |attr, value|
        existing_resource.send("#{attr}=", value) unless locked_fields.include?(attr)
      end

      existing_resource
    end
  end
end
