require 'nokogiri'

module Ingestors
  module ProviderIngestion
    include AutoParsing

    attr_reader :providers

    # Read phase for previews: resolves event/material provider references, fetching Open Graph
    # metadata once per referenced URL. Collects unsaved providers in @providers and assigns
    # them without persisting anything.
    def resolve_providers
      each_provider_reference do |provider, resources|
        resources.each { |resource| resource.content_provider = provider }
      end
    end

    # Resolves and writes providers, then assigns the saved/existing records to their resources.
    # Every referenced URL is fetched once. Rejected new providers are assigned as
    # nil, enabling the source-provider fallback.
    def write_providers(user)
      each_provider_reference do |provider, resources|
        if provider.new_record?
          @stats[:content_providers][:processed] += 1
          provider = write_provider(provider, user)
        end

        resources.each { |resource| resource.content_provider = provider }
      end
    end

    private

    def each_provider_reference
      return unless source.content_provider&.content_provider_type == 'Portal'

      references = (@events + @materials).filter_map do |resource|
        candidate = select_provider_reference(resource)
        [resource, candidate] if candidate
      end

      references.group_by { |_resource, candidate| candidate[:url] }.each do |url, occurrences|
        # Merge every reference to this provider so metadata links from all occurrences survive.
        candidates = occurrences.map(&:last)
        merged = {
          url: url,
          name: candidates.filter_map { |candidate| candidate[:name].presence }.first,
          see_also: candidates.flat_map { |candidate| Array(candidate[:see_also]) }.compact_blank.uniq
        }
        provider = @providers.find { |incoming| incoming.url == url } || resolve_provider_reference(merged)
        @providers << provider if provider.new_record? && !@providers.include?(provider)
        yield provider, occurrences.map(&:first)
      end
    end

    def resolve_provider_reference(candidate)
      existing = ContentProvider.find_by(url: candidate[:url])
      metadata = fetch_provider_metadata(candidate[:see_also] + [candidate[:url]])
      attributes = metadata.merge(title: candidate[:name], url: candidate[:url])
      attributes[:content_provider_type] = existing.content_provider_type if existing
      build_provider(attributes)
    end

    def build_provider(attributes)
      provider = ContentProvider.new(attributes)
      if provider.keywords.blank? && TeSS::Config.feature['auto_parse_vars'].include?('keywords')
        provider.keywords = auto_parse(:keywords, provider.description) || []
      end
      handle_controlled_vocabulary(provider)
    end

    def write_provider(incoming_provider, user)
      existing_provider = ContentProvider.check_exists(incoming_provider)
      return existing_provider unless responsible_for?(existing_provider, incoming_provider, source)

      fields = incoming_provider.changes.transform_values(&:last).symbolize_keys.compact_blank
      provider = existing_provider ? update_resource(existing_provider, fields) : incoming_provider
      provider.user ||= user
      set_resource_defaults(provider, source: source)

      if provider.save
        @stats[:content_providers][existing_provider ? :updated : :added] += 1
        if existing_provider.nil? || provider.log_update_activity?
          provider.create_activity(existing_provider ? :update : :create, owner: user,
                                   parameters: ingestion_activity_parameters)
        end
        provider
      else
        @stats[:content_providers][:rejected] += 1
        fallback = existing_provider ? 'Its existing details were kept.' :
                                      'Its resources will use the source content provider instead.'
        @messages << "Content provider failed validation: #{provider.title} " \
                     "(#{provider.errors.full_messages.join(', ')}). #{fallback}"
        existing_provider&.reload
      end
    end

    def select_provider_reference(resource)
      candidates = Array(resource.try(:providers)).reject do |candidate|
        candidate[:url].blank? || known_node_name?(candidate[:name])
      end
      return if candidates.empty?

      explicit_id = resource.try(:content_provider_id)
      if explicit_id.present?
        explicit_provider = ContentProvider.find_by(id: explicit_id)
        return candidates.find { |candidate| candidate[:url] == explicit_provider&.url }
      end

      candidates.find { |candidate| ContentProvider.exists?(url: candidate[:url]) } || candidates.first
    end

    def known_node_name?(name)
      normalized = name.to_s.strip
      variants = [normalized, normalized.sub(/\AELIXIR\s+/i, '')].map(&:downcase)
      variants.any? { |variant| known_node_names.include?(variant) }
    end

    def known_node_names
      @known_node_names ||= Node.pluck(:name).map { |n| n.to_s.strip.downcase }.to_set
    end

    def fetch_provider_metadata(urls)
      urls = urls.compact_blank.uniq.select do |url|
        valid = valid_http_url?(url)
        @messages << "Invalid content provider metadata URL: #{url}" unless valid
        valid
      end
      # A source-registry link takes precedence over the provider's website.
      host = source_host
      if host
        registry_urls, other_urls = urls.partition { |url| URI.parse(url).host.casecmp?(host) }
        urls = registry_urls + other_urls
      end
      urls.each do |url|
        metadata = scrape_og_metadata(url)
        return metadata if metadata.present?
      end

      {}
    end

    def scrape_og_metadata(url)
      source = open_url(url)
      return {} if source.nil?

      doc = Nokogiri::HTML(source.read)
      description = doc.at("meta[property='og:description']")&.[]('content')
      image = doc.at("meta[property='og:image']")&.[]('content')
      metadata = {
        description: description.presence,
        image_url: (image if valid_http_url?(image))
      }.compact

      keywords = doc.at("meta[name='keywords']")&.[]('content')
      metadata[:keywords] = keywords.split(',').map(&:strip).reject(&:blank?).first(20) if keywords.present?

      metadata
    rescue URI::InvalidURIError, IOError, SocketError, SystemCallError, Timeout::Error,
           OpenSSL::SSL::SSLError, OpenURI::HTTPError => e
      @messages << "Couldn't read content provider metadata from #{url}: #{e.class}: #{e.message}"
      {}
    end

    def valid_http_url?(url)
      return false if url.blank?

      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end
  end
end
