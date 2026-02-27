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

    def filter(source)
      material_count = @materials.length
      event_count = @events.length

      @materials = @materials.select { |m| source.passes_filter? m }
      @events = @events.select { |e| source.passes_filter? e }

      @messages << "#{@materials.length} of #{material_count} materials passed the filters" if @materials.length != material_count
      @messages << "#{@events.length} of #{event_count} events passed the filters" if @events.length != event_count
    end

    def write(user, provider, source: nil)
      filter(source) if source
      write_resources(Event, @events, user, provider, source:)
      @messages << stats_summary(:events)
      write_resources(Material, @materials, user, provider, source:)
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
        URI(url).open(options)
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
      resource.last_scraped = Time.now

      resource
    end

    def write_resources(type, resources, user, provider, source: nil)
      resources.each_with_index do |resource, i|
        key = type.model_name.collection.to_sym
        @stats[key][:processed] += 1

        # check for matched events
        resource.user_id ||= user.id
        resource.content_provider_id ||= provider.id
        resource.space_id ||= source&.space_id
        existing_resource = find_existing(type, resource)

        update = existing_resource
        resource = if update
                     update_resource(existing_resource, resource.to_h)
                   else
                     type.new(resource.to_h)
                   end

        resource.language ||= source&.default_language if resource.has_attribute?(:language) && resource.new_record?

        resource = set_resource_defaults(resource)
        if resource.valid?
          resource.save!
          activity_params = {}
          if source
            activity_params[:source] = {
              id: source.id,
              url: source.url,
              method: source.method
            }
          end
          resource.create_activity(update ? :update : :create, owner: user, parameters: activity_params)
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

    def find_existing(type, resource)
      type.check_exists(resource.to_h)
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
