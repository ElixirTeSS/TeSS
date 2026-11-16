require 'nokogiri'
require 'open-uri'
require 'json'
require 'uri'
require 'cgi'

module Ingestors
  class EudatIngestor < Ingestor
    EUDAT_BASE_HOST = (TeSS::Config.ingestors&.dig(:eudat, :base_host) || 'www.eudat.eu').freeze
    EUDAT_BASE_URL = "https://#{EUDAT_BASE_HOST}".freeze
    EUDAT_HOSTS = [EUDAT_BASE_HOST, 'eudat.eu', 'www.eudat.eu'].uniq.freeze
    EUDAT_LANDING_PAGE = "#{EUDAT_BASE_URL}/eudat-training".freeze

    PROVIDER_NAME = 'EUDAT'

    USER_AGENT = 'TeSS-EUDAT-Ingestor/1.0'
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 20
    MAX_PAGES = 200

    SEED_PAGES = [
      "#{EUDAT_BASE_URL}/b2stage-training-suite",
      "#{EUDAT_BASE_URL}/b2find-training-suite-0"
    ].freeze

    EXCLUDED_PATHS = %r{
      \A/(?:news|events|contact|about|search|user|login|privacy|terms|blog)
      (?:/|$)
    }ix

    FILE_EXTENSIONS = %w[
      pdf ppt pptx odp doc docx odt mp4 webm mov
    ].freeze

    attr_reader :resources, :materials, :events

    def initialize
      super

      @visited_pages = Set.new
      @resource_urls = Set.new
      @resources = []
      @materials = []
      @events = []
    end

    def self.config
      {
        key: 'eudat_ingestor',
        title: 'EUDAT',
        category: :any,
        description: 'Ingestor for the EUDAT training modules',
        parameters: {}
      }
    end

    def read(source_url = nil)
      start_url = source_url.presence || EUDAT_LANDING_PAGE

      raise ArgumentError, "Invalid EUDAT URL: #{start_url}" unless valid_crawl_url?(start_url)

      @materials = []
      @events = []
      @resources = []
      @resource_urls = Set.new
      @visited_pages = Set.new

      queue = [canonicalize_url(start_url)]
      queued = Set.new(queue.compact)
      material_urls = Set.new

      pages_visited = 0

      Rails.logger.info("[EUDAT] STARTING harvest from URL: #{start_url}")

      until queue.empty? || pages_visited >= MAX_PAGES
        url = queue.shift
        next unless url
        next if @visited_pages.include?(url)

        @visited_pages.add(url)

        begin
          document = fetch_document(url)
          next unless document

          pages_visited += 1

          # Extract the primary training page.
          material = extract_resource(document, url)

          if material.is_a?(Hash) && material[:title].present?
            material_url = canonicalize_url(material[:url] || url)

            add_resource(material) if material_url && material_urls.add?(material_url)
          end

          # Extract linked documents and external learning resources.
          extract_linked_resources(document, url).each do |linked|
            next unless linked.is_a?(Hash)
            next if linked[:title].blank? || linked[:url].blank?

            material_url = canonicalize_url(linked[:url])
            next unless material_url
            next unless material_urls.add?(material_url)

            add_resource(linked)
          end

          # Discover further EUDAT training pages.
          document.css('a[href]').each do |anchor|
            candidate = absolute_url_for(anchor['href'], url)
            next unless candidate
            next unless valid_crawl_url?(candidate)
            next unless training_page?(candidate)

            candidate = canonicalize_url(candidate)
            next unless candidate
            next if @visited_pages.include?(candidate)
            next unless queued.add?(candidate)
            next if @visited_pages.size + queue.size >= MAX_PAGES

            queue << candidate
          end
        rescue StandardError => e
          Rails.logger.warn(
            "[EUDAT] Failed to process URL: #{url}, #{e.class}: #{e.message}"
          )
        end
      end

      Rails.logger.info('[EUDAT] ========== Summary Report ==========')
      Rails.logger.info("[EUDAT] Pages visited: #{pages_visited}")
      Rails.logger.info("[EUDAT] Materials discovered: #{materials.size}")
      Rails.logger.info("[EUDAT] Events discovered: #{events.size}")
      Rails.logger.info('[EUDAT] ====================================')

      # puts "\n[EUDAT] Harvest completed."
      # puts "[EUDAT] Pages visited: #{pages_visited}"
      # puts "[EUDAT] Materials discovered: #{materials.size}"
      # puts "[EUDAT] Events discovered: #{events.size}"

      {
        materials: @materials,
        events: @events
      }
    end

    # Discover training pages and collect their resources.
    def ingest
      discover_training_pages.each do |url|
        document = fetch_document(url)
        next unless document

        add_resource(extract_resource(document, url))

        extract_linked_resources(document, url).each do |resource|
          add_resource(resource)
        end
      end

      # Keep the worker-facing collection initialized and synchronized.
      @materials = @resources.dup

      puts(
        '[EUDAT] Ingestion complete: ' \
        "#{@resources.size} resources from " \
        "#{@visited_pages.size} pages."
      )

      @resources
    end

    private

    def print_material(record)
      Rails.logger.info("  Title:        #{record[:title]&.truncate(100)} [..]")
      Rails.logger.info("  URL:          #{record[:url]}")
      Rails.logger.info("  Type:         #{record[:resource_type]}")
      Rails.logger.info("  Provider:     #{record[:provider]}")
      Rails.logger.info("  Description:  #{record[:description]&.truncate(100)}[..]")
      Rails.logger.info("  Keywords:     #{Array(record[:keywords]).join(', ')}")
      Rails.logger.info('---------------------------------------------------------------------')
    end

    def discover_training_pages
      urls = Set.new
      queue = [EUDAT_LANDING_PAGE, *SEED_PAGES]

      until queue.empty? || @visited_pages.size >= MAX_PAGES
        current_url = canonicalize_url(queue.shift)
        next unless current_url
        next if @visited_pages.include?(current_url)

        document = fetch_document(current_url)
        next unless document

        @visited_pages.add(current_url)
        urls.add(current_url)

        document.css('a[href]').each do |anchor|
          candidate = absolute_url_for(anchor['href'], current_url)
          next unless candidate
          next unless training_page?(candidate)

          urls.add(candidate)
          queue << candidate unless @visited_pages.include?(candidate)
        end
      end

      urls.to_a
    end

    def fetch_document(url)
      response = URI.open(
        url,
        'User-Agent' => USER_AGENT,
        'Accept' => 'text/html,application/xhtml+xml',
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT,
        redirect: true
      )

      return nil unless response.content_type.to_s.include?('html')

      Nokogiri::HTML(response.read)
    rescue StandardError => e
      warn "[EUDAT] Fetch failed for #{url}: #{e.class}: #{e.message}"
      nil
    end

    def training_page?(url)
      uri = URI.parse(url)

      return false unless uri.scheme == 'https'
      return false unless EUDAT_HOSTS.include?(uri.host)
      return false if uri.path.match?(EXCLUDED_PATHS)

      return false if uri.path.match?(
        /\.(?:jpg|jpeg|png|gif|svg|css|js|xml|json|zip|gz)$/i
      )

      uri.path.match?(
        /training|tutorial|learning|workshop|webinar|b2(drop|share|safe|stage|find|access|handle)/i
      )
    rescue URI::InvalidURIError
      false
    end

    def extract_resource(document, source_url)
      metadata = extract_json_ld(document)

      title =
        metadata['name'] ||
        metadata['headline'] ||
        meta_content(document, 'meta[property="og:title"]') ||
        document.at_css('main h1')&.text ||
        document.at_css('h1')&.text ||
        document.at_css('title')&.text

      description =
        metadata['description'] ||
        meta_content(document, 'meta[name="description"]') ||
        meta_content(document, 'meta[property="og:description"]') ||
        document.at_css('main article p, main .field--name-body p, main p')&.text

      {
        title: clean(title),
        description: clean(description),
        url: canonical_url(document, source_url),
        provider: PROVIDER_NAME,
        resource_type: infer_resource_type(document, source_url),
        keywords: extract_keywords(document, metadata)
      }
    end

    def extract_json_ld(document)
      document.css('script[type="application/ld+json"]').each do |script|
        parsed = JSON.parse(script.text)
        objects = parsed.is_a?(Array) ? parsed : [parsed]

        objects.each do |object|
          next unless object.is_a?(Hash)

          candidates = object['@graph'].is_a?(Array) ? object['@graph'] : [object]

          candidates.each do |candidate|
            next unless candidate.is_a?(Hash)

            types = Array(candidate['@type'])
            return candidate if (
              types & %w[
                LearningResource Course CourseInstance
                CreativeWork VideoObject HowTo
              ]
            ).any?
          end
        end
      rescue JSON::ParserError
        next
      end

      {}
    end

    def extract_linked_resources(document, page_url)
      records = []

      document.css('a[href]').each do |anchor|
        url = absolute_url_for(anchor['href'], page_url)
        next unless url

        uri = URI.parse(url)
        extension = File.extname(uri.path).delete_prefix('.').downcase

        if FILE_EXTENSIONS.include?(extension)
          title = clean(anchor.text)
          title = File.basename(uri.path).tr('_-', ' ').sub(/\.[^.]+$/, '') if title.empty?

          records << {
            title: title,
            description: 'Training resource linked from EUDAT.',
            url: url,
            provider: PROVIDER_NAME,
            resource_type: infer_file_type(extension),
            keywords: %w[EUDAT training]
          }

          next
        end

        text = clean(anchor.text)
        next unless external_training_link?(url, text)

        records << {
          title: text,
          description: 'Learning resource linked from EUDAT training content.',
          url: url,
          provider: PROVIDER_NAME,
          resource_type: 'learning_resource',
          keywords: %w[EUDAT training hands-on]
        }
      rescue URI::InvalidURIError
        next
      end

      records
    end

    def external_training_link?(url, text)
      uri = URI.parse(url)

      return false if EUDAT_HOSTS.include?(uri.host)
      return false unless uri.scheme == 'https'
      return false if text.empty?

      text.match?(/training|tutorial|hands.on|learning|course|presentation|slides/i) ||
        url.match?(%r{github\.com/EUDAT-Training|training|tutorial}i)
    rescue URI::InvalidURIError
      false
    end

    def extract_keywords(document, metadata)
      values = []

      raw = metadata['keywords']
      values.concat(raw.is_a?(Array) ? raw : raw.to_s.split(','))

      values.concat(
        meta_content(document, 'meta[name="keywords"]').to_s.split(',')
      )

      values.concat(
        %w[
          EUDAT research-data-management FAIR
          B2DROP B2SHARE B2FIND B2SAFE
          B2STAGE B2ACCESS B2HANDLE
        ]
      )

      values.map { |value| clean(value) }.reject(&:empty?).uniq
    end

    def infer_resource_type(document, url)
      path = URI.parse(url).path.downcase

      return 'video' if path.match?(/\.(mp4|webm|mov)$/)
      return 'presentation' if path.match?(/\.(ppt|pptx|odp)$/)
      return 'document' if path.match?(/\.(pdf|doc|docx|odt)$/)

      return 'video' if meta_content(
        document, 'meta[property="og:type"]'
      ).to_s.include?('video')

      'learning_resource'
    rescue URI::InvalidURIError
      'learning_resource'
    end

    def infer_file_type(extension)
      case extension
      when 'pdf', 'doc', 'docx', 'odt'
        'document'
      when 'ppt', 'pptx', 'odp'
        'presentation'
      when 'mp4', 'webm', 'mov'
        'video'
      else
        'learning_resource'
      end
    end

    def canonical_url(document, fallback)
      href = document.at_css('link[rel="canonical"]')&.[]('href')
      return fallback if href.to_s.strip.empty?

      absolute_url_for(href, fallback) || fallback
    end

    def absolute_url_for(href, base_url)
      return nil if href.to_s.strip.empty?

      uri = URI.join(base_url, href)
      return nil unless %w[http https].include?(uri.scheme)

      uri.host = EUDAT_BASE_HOST if EUDAT_HOSTS.include?(uri.host)
      uri.fragment = nil
      uri.query = nil
      uri.to_s
    rescue URI::InvalidURIError
      nil
    end

    def canonicalize_url(url)
      absolute_url_for(url, EUDAT_LANDING_PAGE)
    end

    def meta_content(document, selector)
      document.at_css(selector)&.[]('content')
    end

    def clean(value)
      CGI.unescapeHTML(value.to_s).gsub(/\s+/, ' ').strip
    end

    def add_resource(record)
      return unless record.is_a?(Hash)
      return if record[:title].to_s.empty?
      return unless record[:url].to_s.start_with?('https://')
      return if @resource_urls.include?(record[:url])

      material = Material.new(
        title: record[:title],
        description: record[:description],
        url: record[:url],
        resource_type: record[:resource_type],
        keywords: record[:keywords]
      )

      @resource_urls.add(record[:url])
      @resources << material
      @materials << material

      Rails.logger.info('[EUDAT] Material added!')
      print_material(record)
    end

    def valid_crawl_url?(url)
      uri = URI.parse(url.to_s)

      uri.scheme == 'https' &&
        EUDAT_HOSTS.include?(uri.host) &&
        !uri.path.match?(EXCLUDED_PATHS)
    rescue URI::InvalidURIError
      false
    end
  end
end
