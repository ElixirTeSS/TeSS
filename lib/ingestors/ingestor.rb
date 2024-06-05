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
      summary = "\n### #{type.to_s.titleize}\n\n"

      [:processed, :added, :updated, :rejected].each do |key|
        summary += " - #{key.to_s.titleize}: #{stats[type][key]}\n"
      end

      summary
    end

    def open_url(url, raise: false)
      options = {
        redirect: false, # We're doing redirects manually below, since open-uri can't handle http -> https redirection
        read_timeout: 5
      }
      options[:ssl_verify_mode] = config[:ssl_verify_mode] if config.key?(:ssl_verify_mode)
      redirect_attempts = 5
      begin
        URI(url).open(options)
      rescue OpenURI::HTTPRedirect => e
        url = e.uri.to_s
        retry if (redirect_attempts -= 1) > 0
        raise e
      rescue OpenURI::HTTPError => e
        if raise
          raise e
        else
          @messages << "Couldn't open URL #{url}: #{e}"
          nil
        end
      end
    end

    def convert_description(input)
      return input if input.nil?

      if input.match?(/<(li|p|b|i|ul|div|br|strong|em|h1)\/?>/)
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

    def write_resources(type, resources, user, provider)
      resources.each_with_index do |resource, i|
        key = type.model_name.collection.to_sym
        @stats[key][:processed] += 1

        # check for matched events
        resource.user_id ||= user.id
        resource.content_provider_id ||= provider.id
        llm_attr = resource.delete_field(:llm_object_attributes)
        resource = OpenStruct.new(resource.to_h.select { |key, _| type.attribute_names.map(&:to_sym).include?(key)})
        existing_resource = find_existing(type, resource)

        update = existing_resource
        resource = if update
                     update_resource(existing_resource, resource.to_h)
                   else
                     type.new(resource.to_h)
                   end

        resource = set_resource_defaults(resource)
        if resource.valid?
          resource.save!
          @stats[key][update ? :updated : :added] += 1
          if llm_attr
            llm_object = LlmObject.new(llm_attr.to_h)
            if type == Event
              llm_object.event_id = resource.id
            elsif type == Material
              llm_object.material_id = resource.id
            end
            llm_object.save!
            resource.llm_object = llm_object
            if resource.valid?
              resource.save!
            end
          end
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
      locked_fields = existing_resource.locked_fields

      fields.except(:content_provider_id, :user_id).each do |attr, value|
        existing_resource.send("#{attr}=", value) unless locked_fields.include?(attr)
      end

      existing_resource
    end
  end
end
