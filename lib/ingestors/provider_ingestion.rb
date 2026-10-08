require 'nokogiri'

module Ingestors
  module ProviderIngestion
    include AutoParsing

    OG_METADATA_MAP = {
      'og:title' => :title,
      'og:description' => :description,
      'og:image' => :image_url,
      'og:url' => :url
    }.freeze

    # Returns a ContentProvider (persisted or unsaved) for the first extracted
    # provider that is not a known node, or nil if there are no candidates.
    def find_provider_by_extracted_urls(providers)
      candidates = Array(providers).select { |p| provider_candidate?(p) }
      return nil if candidates.empty?

      candidates.each do |provider_hash|
        existing = ContentProvider.find_by(url: provider_url(provider_hash))
        return existing if existing
      end

      # Prefer a candidate whose page provides extra metadata, but accept any.
      candidates.each do |provider_hash|
        provider = cached_provider(provider_hash)
        return provider if provider_metadata_sufficient?(provider)
      end

      cached_provider(candidates.first)
    end

    def providers
      provider_cache.values
    end

    # Persists providers referenced by resources that survived filtering.
    def write_providers(user)
      referenced_providers.each do |provider|
        next if provider.persisted?

        provider.user ||= user
        if provider.save
          @stats[:content_providers][:added] += 1
          provider.create_activity(:create, owner: user)
        else
          @stats[:content_providers][:rejected] += 1
          @messages << "Content provider failed validation: #{provider.title} " \
                       "(#{provider.errors.full_messages.join(', ')})"
        end
      end
    end

    private

    def provider_candidate?(provider_hash)
      return false unless provider_hash.is_a?(Hash)

      url = provider_url(provider_hash)
      return false if url.blank?

      name = provider_hash[:name] || provider_hash['name']
      return false if name.present? && known_node_name?(name)

      true
    end

    def known_node_name?(name)
      normalized = name.to_s.strip
      variants = [normalized, normalized.sub(/\AELIXIR\s+/i, '')].map(&:downcase)
      variants.any? { |variant| known_node_names.include?(variant) }
    end

    def known_node_names
      @known_node_names ||= Node.pluck(:name).map { |n| n.to_s.strip.downcase }.to_set
    end

    def provider_metadata_sufficient?(provider)
      provider.description.present? || provider.image_url.present?
    end

    def provider_cache
      @provider_cache ||= {}
    end

    def referenced_providers
      (@events + @materials).filter_map { |r| r.try(:content_provider) }.uniq
    end

    def provider_url(provider_hash)
      provider_hash[:url] || provider_hash['url']
    end

    def cached_provider(provider_hash)
      provider_cache[provider_url(provider_hash)] ||= build_provider(provider_hash)
    end

    def build_provider(raw_provider)
      name = raw_provider[:name] || raw_provider['name']
      url = raw_provider[:url] || raw_provider['url']
      see_also = raw_provider[:see_also] || raw_provider['see_also']

      # Fallback to the provider's own URL if no see_also URLs are provided
      metadata_urls = see_also.present? ? see_also : [url].compact

      metadata = fetch_provider_metadata(metadata_urls)

      attributes = metadata.merge({ title: name, url: url }.compact)
      provider = ContentProvider.new(attributes)
      provider = handle_auto_parsing(provider)
      provider = handle_controlled_vocabulary(provider)
      provider
    end

    def fetch_provider_metadata(urls)
      metadata = Array(urls).filter_map do |url|
        next if url.blank?

        extract_og_metadata(url)
      end
      metadata.max_by do |item|
        [item[:description].present? || item[:image_url].present? ? 1 : 0, item.size]
      end || {}
    end

    def extract_og_metadata(url)
      @metadata_cache ||= {}
      return @metadata_cache[url] if @metadata_cache.key?(url)

      @metadata_cache[url] = scrape_og_metadata(url)
    end

    def scrape_og_metadata(url)
      source = open_url(url)
      return {} if source.nil?

      doc = Nokogiri::HTML(source.read)
      metadata = {}

      OG_METADATA_MAP.each do |property, attribute|
        content = doc.at("meta[property='#{property}']")&.[]('content')
        metadata[attribute] = content if content.present?
      end

      metadata[:image_url] = nil unless valid_http_url?(metadata[:image_url])
      metadata.compact!

      keywords = doc.at("meta[name='keywords']")&.[]('content')
      metadata[:keywords] = keywords.split(',').map(&:strip).reject(&:blank?).first(20) if keywords.present?

      metadata
    rescue URI::InvalidURIError, IOError, SocketError, SystemCallError, Timeout::Error,
           OpenSSL::SSL::SSLError, OpenURI::HTTPError, OpenURI::HTTPRedirect, Nokogiri::SyntaxError
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
