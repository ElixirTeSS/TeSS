require 'sitemap-parser'
require 'private_address_check'
require 'private_address_check/tcpsocket_ext'

module Ingestors
  class Ingestor
    include EventIngestion
    include MaterialIngestion
    include ProviderIngestion

    def initialize
      @source = Source.new
      @messages = []
      @stats = {
        events: { processed: 0, added: 0, updated: 0, rejected: 0 },
        materials: { processed: 0, added: 0, updated: 0, rejected: 0 },
        content_providers: { processed: 0, added: 0, updated: 0, rejected: 0 }
      }
      @token = ''
      @events = []
      @materials = []
      @providers = []
    end

    # accessor methods
    attr_reader :messages, :stats, :events, :materials, :source
    # `token`/`@token` are kept for backwards compatibility with ingestors
    # maintained outside this repository that read or override them directly.
    attr_accessor :token

    def source=(value)
      raise ArgumentError, 'Ingestor source must be a Source' unless value.is_a?(Source)

      @source = value
      @token = value.token || ''
    end

    def source_host
      URI.parse(source.url).host if source.url.present?
    end

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

    def filter
      material_count = @materials.length
      event_count = @events.length

      @materials = @materials.select { |m| source.passes_filter? m }
      @events = @events.select { |e| source.passes_filter? e }

      @messages << "#{@materials.length} of #{material_count} materials passed the filters" if @materials.length != material_count
      @messages << "#{@events.length} of #{event_count} events passed the filters" if @events.length != event_count
    end

    def write(user)
      provider = source.content_provider
      raise ArgumentError, 'A content provider is required to write ingested resources' unless provider

      filter
      write_providers(user)
      @messages << stats_summary(:content_providers) if @stats[:content_providers][:processed].positive?
      write_resources(Event, @events, user, provider)
      @messages << stats_summary(:events)
      write_resources(Material, @materials, user, provider)
      @messages << stats_summary(:materials)
    end

    def stats_summary(type)
      summary = "\n### #{type.to_s.titleize}\n\n"

      %i[processed added updated rejected].each do |key|
        summary += " - #{key.to_s.titleize}: #{stats[type][key]}\n"
      end

      summary
    end

    def open_url(url, raise: false, token: nil)
      options = {
        redirect: false, # We're doing redirects manually below, since open-uri can't handle http -> https redirection
        read_timeout: 30 # 5
      }
      options[:ssl_verify_mode] = config[:ssl_verify_mode] if config.key?(:ssl_verify_mode)
      redirect_attempts = 5
      options['Authorization'] = "Bearer #{token}" unless token.nil?
      begin
        PrivateAddressCheck.only_public_connections do
          URI(url).open(options)
        end
      rescue PrivateAddressCheck::PrivateConnectionAttemptedError
        raise "Couldn't open URL #{url}" if raise
        @messages << "Couldn't open URL #{url}"

        nil
      rescue OpenURI::HTTPRedirect => e
        url = e.uri.to_s
        retry if (redirect_attempts -= 1) > 0
        raise e
      rescue OpenURI::HTTPError => e
        raise e if raise

        @messages << "Couldn't open URL #{url}: #{e}"
        nil
      end
    end

    def get_html_from_url(url)
      response = HTTParty.get(url, follow_redirects: true, headers: { 'User-Agent' => config[:user_agent] })
      Nokogiri::HTML(response.body)
    end

    # Some URLs automatically redirects the user to another webpage
    # This method gets a URL and returns the last redirected URL (as shown by a 30X response or a `meta[http-equiv="Refresh"]` tag)
    def get_redirected_url(url, limit = 5) # rubocop:disable Metrics/AbcSize
      raise 'Too many redirects' if limit.zero?

      https_url = to_https(url) # some `homepage` were http
      response = HTTParty.get(https_url, follow_redirects: true, headers: { 'User-Agent' => config[:user_agent] || 'TeSS Bot' })
      return https_url unless response.headers['content-type']&.include?('html')

      doc = Nokogiri::HTML(response.body)
      meta = doc.at('meta[http-equiv="Refresh"]')
      if meta && meta.to_s =~ /url=(.+)/i
        content = meta['content']
        relative_path = content[/url=(.+)/i, 1]
        base = https_url.end_with?('/') ? https_url : "#{https_url}/"
        escaped_path = URI::DEFAULT_PARSER.escape(relative_path).to_s
        new_url = "#{base}#{escaped_path}"
        return get_redirected_url(new_url, limit - 1)
      end
      https_url
    end

    def to_https(url)
      uri = URI.parse(url)
      uri.scheme = 'https'
      uri.to_s
    end

    def convert_description(input)
      return input if input.nil?

      if input.match?(%r{<(li|p|b|i|ul|div|br|strong|em|h1)/?>})
        ReverseMarkdown.convert(input, tag_border: '').strip
      else
        input
      end
    end

    def convert_title(input)
      return input if input.nil?

      CGI.unescapeHTML(input)
    end

    def get_json_response(url, accept_params = 'application/json', **kwargs)
      response = RestClient::Request.new({ method: :get,
                                           url: CGI.unescape_html(url),
                                           verify_ssl: false,
                                           headers: { accept: accept_params } }.merge(kwargs)).execute
      # check response
      raise "invalid response code: #{response.code}" unless response.code == 200

      JSON.parse(response.to_str)
    end

    def ingested
      @events.count + @materials.count
    end

    def processed
      @stats.values_at(:events, :materials).sum { |s| s[:processed] }
    end

    def added
      @stats.values_at(:events, :materials).sum { |s| s[:added] }
    end

    def updated
      @stats.values_at(:events, :materials).sum { |s| s[:updated] }
    end

    def rejected
      @stats.values_at(:events, :materials).sum { |s| s[:rejected] }
    end

    private

    def set_resource_defaults(resource, source: nil)
      resource.scraper_record = true
      resource.last_scraped = Time.now
      resource.last_scraped_by_source = source if source&.persisted?

      resource
    end

    def ingestion_activity_parameters
      return {} unless source.persisted?

      { source: { id: source.id, url: source.url, method: source.method } }
    end

    def write_resources(type, resources, user, provider)
      resources.each_with_index do |resource, i|
        key = type.model_name.collection.to_sym
        @stats[key][:processed] += 1

        fields = resource.to_h.except(:content_provider, :providers)
        fields[:user_id] ||= user.id
        fields[:content_provider_id] ||= resource.try(:content_provider)&.id || provider.id
        fields[:space_id] ||= source.space_id
        existing_resource = find_existing(type, fields)

        next unless responsible_for?(existing_resource, resource, source)

        update = existing_resource
        resource = update ? update_resource(existing_resource, fields) : type.new(fields)

        resource.language ||= source.default_language if resource.has_attribute?(:language) && resource.new_record?

        resource = set_resource_defaults(resource, source: source)
        if resource.valid?
          resource.save!
          if update
            if resource.log_update_activity?
              resource.create_activity(:update, owner: user, parameters: ingestion_activity_parameters)
            end
          else
            resource.create_activity(:create, owner: user, parameters: ingestion_activity_parameters)
          end
          @stats[key][update ? :updated : :added] += 1
        else
          @stats[key][:rejected] += 1
          title = resource.title
          title = "[#{title}](#{resource.url})" if resource.url
          @messages << "\n#{type.model_name.human} failed validation: #{title}\n"
          resource.errors.full_messages.each do |m|
            @messages << " - #{m}"
          end
        end

        resources[i] = resource
      end
    end

    def responsible_for?(existing_resource, new_resource, source)
      # Stay with the existing source if there is one, to avoid constantly changing metadata back and forth.
      # Switch responsibility if the new source provides a higher number of considered metadata fields, or
      # if the considered field count is the same but a significantly longer description is available.
      # This prefers a source closest to the original one (likely the first) and switches sources when
      # originally scraped simple metadata is extended manually at an intermediate source.
      # When there are no external changes, the source can only switch a limited number of times.

      return true unless source && existing_resource
      return true if existing_resource.last_scraped_by_source.nil?
      return true if existing_resource.last_scraped_by_source == source

      existing_fields = existing_resource.attributes.symbolize_keys
      incoming_fields = new_resource.is_a?(ContentProvider) ? new_resource.attributes.symbolize_keys : new_resource
      if existing_resource.is_a?(ContentProvider)
        existing_fields[:image_url] = existing_resource.image_url.presence || existing_resource.image_file_name.presence
        FieldLock.strip_locked_fields(existing_fields, existing_resource.locked_fields)
        FieldLock.strip_locked_fields(incoming_fields, existing_resource.locked_fields)
      end

      considered_fields = %i[title url doi description resource_type prerequisites keywords start end sponsors
                            venue city county postcode cost_value target_audience contact language image_url]
      existing_count = considered_fields.count { |field| existing_fields[field].present? }
      incoming_count = considered_fields.count { |field| incoming_fields[field].present? }
      return true if incoming_count > existing_count

      description_fields = %i[description prerequisites learning_objectives tech_requirements]
      existing_length = description_fields.sum { |field| existing_fields[field].to_s.length }
      incoming_length = description_fields.sum { |field| incoming_fields[field].to_s.length }
      incoming_count == existing_count && incoming_length > existing_length * 1.5
    end

    def find_existing(type, resource)
      type.check_exists(resource)
    end

    def update_resource(existing_resource, fields)
      # overwrite unlocked attributes
      FieldLock.strip_locked_fields(fields, existing_resource.locked_fields)

      fields.except(:content_provider_id, :user_id).each do |attr, value|
        existing_resource.send("#{attr}=", value)
      end

      existing_resource
    end
  end
end
