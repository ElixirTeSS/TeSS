require 'nokogiri'

module Ingestors
  module ProviderIngestion
    include AutoParsing

    OG_METADATA_MAP = {
      'og:description' => :description,
      'og:image' => :image_url
    }.freeze

    def find_provider_by_extracted_urls(extracted_providers)
      candidates = (extracted_providers || []).reject do |candidate|
        candidate[:url].blank? || known_node_name?(candidate[:name])
      end

      candidates.each do |candidate|
        existing = ContentProvider.find_by(url: candidate[:url])
        return existing if existing
      end

      candidate = candidates.first
      return unless candidate

      @provider_cache[candidate[:url]] ||= build_provider(candidate)
    end

    def providers
      (@events + @materials).filter_map { |resource| resource.try(:content_provider) }.uniq
    end

    def write_providers(user)
      providers.each do |provider|
        next if provider.persisted?

        provider.user ||= user
        if provider.save
          @stats[:content_providers][:added] += 1
          provider.create_activity(:create, owner: user)
        else
          @stats[:content_providers][:rejected] += 1
          @messages << "Content provider failed validation: #{provider.title} " \
                       "(#{provider.errors.full_messages.join(', ')}). " \
                       'Its resources will use the source content provider instead.'
        end
      end
    end

    private

    def known_node_name?(name)
      normalized = name.to_s.strip
      variants = [normalized, normalized.sub(/\AELIXIR\s+/i, '')].map(&:downcase)
      variants.any? { |variant| known_node_names.include?(variant) }
    end

    def known_node_names
      @known_node_names ||= Node.pluck(:name).map { |n| n.to_s.strip.downcase }.to_set
    end

    def build_provider(raw_provider)
      metadata_urls = (Array(raw_provider[:see_also]) + [raw_provider[:url]]).compact_blank.uniq
      metadata = fetch_provider_metadata(metadata_urls)
      provider = ContentProvider.new(metadata.merge(title: raw_provider[:name], url: raw_provider[:url]))
      if provider.keywords.blank? && TeSS::Config.feature['auto_parse_vars'].include?('keywords')
        provider.keywords = auto_parse(:keywords, provider.description) || []
      end
      handle_controlled_vocabulary(provider)
    end

    def fetch_provider_metadata(urls)
      urls = urls.select do |url|
        valid = valid_http_url?(url)
        @messages << "Invalid content provider metadata URL: #{url}" unless valid
        valid
      end
      # A source-registry link takes precedence over the provider's website.
      if provider_metadata_host
        registry_urls, other_urls = urls.partition { |url| URI.parse(url).host.casecmp?(provider_metadata_host) }
        urls = registry_urls + other_urls
      end
      urls.each do |url|
        metadata = if @provider_metadata_cache.key?(url)
                     @provider_metadata_cache[url]
                   else
                     @provider_metadata_cache[url] = scrape_og_metadata(url)
                   end
        return metadata if metadata.present?
      end

      {}
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
           OpenSSL::SSL::SSLError, OpenURI::HTTPError, OpenURI::HTTPRedirect, Nokogiri::SyntaxError => e
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
