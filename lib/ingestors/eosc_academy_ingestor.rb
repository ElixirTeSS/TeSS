require 'nokogiri'
require 'open-uri'
require 'json'
require 'uri'
require 'cgi'
require 'time'

module Ingestors
  class EoscAcademyIngestor < Ingestor
    EOSC_BASE_HOST = (TeSS::Config.ingestors&.dig(:eosc, :base_host) || 'eosc.eu').freeze
    EOSC_BASE_URL = "https://#{EOSC_BASE_HOST}".freeze
    EOSC_HOSTS = [EOSC_BASE_HOST, 'eosc.eu', 'www.eosc.eu'].uniq.freeze
    LANDING_PAGE = "#{EOSC_BASE_URL}/academy".freeze

    PROVIDER_NAME = 'Academy'.freeze
    USER_AGENT = 'TeSS-EOSC-Academy-Ingestor/1.0'.freeze

    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30
    MAX_PAGES = 200

    SEED_PAGES = [
      LANDING_PAGE,
      "#{EOSC_BASE_URL}/events"
    ].freeze

    FILE_EXTENSIONS = %w[
      pdf ppt pptx odp doc docx odt
      mp4 webm mov
    ].freeze

    EXCLUDED_PATHS = %r{
      \A/(?:news|contact|about|search|user|login|privacy|terms|wp-admin)
      (?:/|$)
    }ix

    attr_reader :resources, :materials, :events

    def initialize
      super
      reset_state
    end

    def self.config
      {
        key: 'eosc_academy_ingestor',
        title: 'EOSC Academy',
        category: :any,
        description: 'Harvests courses, events and learning materials from EOSC Academy',
        parameters: {}
      }
    end

    # --------------------------------------------------
    # Main harvest method
    # --------------------------------------------------

    def read(source_url = nil)
      reset_state

      start_url = source_url.presence || LANDING_PAGE

      raise ArgumentError, "Invalid EOSC Academy URL: #{start_url}" unless valid_crawl_url?(start_url)

      queue = [canonicalize_url(start_url)]
      queued = Set.new(queue.compact)

      SEED_PAGES.each do |seed|
        canonical = canonicalize_url(seed)
        next unless canonical
        next unless queued.add?(canonical)

        queue << canonical
      end

      Rails.logger.info(
        "[EOSC] STARTING harvest from URL: #{start_url}"
      )

      pages_visited = 0

      until queue.empty? || pages_visited >= MAX_PAGES

        url = queue.shift

        next unless url
        next if @visited_pages.include?(url)

        @visited_pages.add(url)

        begin
          document = fetch_document(url)
          next unless document

          pages_visited += 1

          metadata = extract_json_ld(document)

          is_academy_page = academy_material_page?(url, metadata)

          # ------------------------------------------
          # Academy materials
          # ------------------------------------------

          if is_academy_page
            resource = extract_resource(document, url, metadata)
            add_resource(resource) if resource

            # Extract linked files and external learning
            # resources only from Academy pages.
            extract_linked_resources(document, url).each do |linked|
              add_resource(linked)
            end
          end

          # ------------------------------------------
          # Events
          # ------------------------------------------

          if event_page?(url, document, metadata)
            event = extract_event(document, url, metadata)
            add_event(event) if event
          end

          # ------------------------------------------
          # Discover further pages
          # ------------------------------------------

          document.css('a[href]').each do |anchor|
            candidate = absolute_url_for(anchor['href'], url)

            next unless candidate
            next unless valid_crawl_url?(candidate)
            next unless relevant_page?(candidate)

            candidate = canonicalize_url(candidate)

            next unless candidate
            next if @visited_pages.include?(candidate)
            next unless queued.add?(candidate)

            next if @visited_pages.size + queue.size >= MAX_PAGES

            queue << candidate
          end
        rescue StandardError => e
          Rails.logger.warn(
            "[EOSC] Failed processing #{url}: #{e.class}: #{e.message}"
          )

          Rails.logger.debug(e.backtrace.join("\n")) if e.backtrace
        end
      end

      # Keep the public collections consistent.
      @materials = @resources.dup

      Rails.logger.info(
        '[EOSC] Harvest complete: ' \
        "pages=#{pages_visited}, " \
        "materials=#{@materials.size}, " \
        "events=#{@events.size}"
      )

      Rails.logger.info('[EOSC] ======== Summary Report ========')
      Rails.logger.info("[EOSC] Pages visited: #{pages_visited}")
      Rails.logger.info("[EOSC] Materials discovered: #{@materials.size}")
      Rails.logger.info("[EOSC] Events discovered: #{@events.size}")
      Rails.logger.info('[EOSC] ================================')

      {
        materials: @materials,
        events: @events
      }
    end

    def ingest
      result = read

      @materials = result[:materials]

      @materials
    end

    private

    # --------------------------------------------------
    # State initialization
    # --------------------------------------------------

    def reset_state
      @visited_pages = Set.new

      @resource_urls = Set.new

      @event_urls = Set.new

      # This was missing in the original implementation.
      # add_event uses this set for event deduplication.
      @event_keys = Set.new

      @resources = []
      @materials = []
      @events = []
    end

    # --------------------------------------------------
    # HTTP
    # --------------------------------------------------

    def fetch_document(url)
      uri = URI.parse(url)
      return nil unless uri.is_a?(URI::HTTP)

      response = uri.open(
        'User-Agent' => USER_AGENT,
        'Accept' => 'text/html,application/xhtml+xml',
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT
      )

      return nil unless response.content_type.to_s.include?('html')

      Nokogiri::HTML(response.read)
    rescue StandardError => e
      Rails.logger.warn(
        "[EOSC] Fetch failed: #{url} [#{e.message}]"
      )

      nil
    end

    # --------------------------------------------------
    # URL filtering
    # --------------------------------------------------

    def valid_crawl_url?(url)
      uri = URI.parse(url.to_s)

      return false unless uri.scheme == 'https'

      return false unless EOSC_HOSTS.include?(uri.host)
      return false if uri.path.match?(EXCLUDED_PATHS)

      true
    rescue URI::InvalidURIError
      false
    end

    def relevant_page?(url)
      uri = URI.parse(url)

      path = uri.path.downcase

      # /events/YYYY-MM-DD pages do not exist (404) - these are wrongly generated
      # calendar-day links on calendar web page
      return false if path.match?(%r{\A/events/\d{4}-\d{2}-\d{2}/?\z})

      return true if path == '/academy'
      return true if path.start_with?('/academy/')

      return true if path == '/events'
      return true if path.start_with?('/events/')

      false
    rescue URI::InvalidURIError
      false
    end

    # --------------------------------------------------
    # Event page detection
    # --------------------------------------------------

    def event_page?(url, _document, _metadata)
      uri = URI.parse(url)

      segments = uri.path.split('/').reject(&:empty?)

      return false unless segments.first == 'events'

      # Only individual event detail pages:
      # /events/gaia-x-summit-2026
      return false unless segments.length == 2

      slug = segments.last

      # Exclude date archive URLs.
      return false if slug.match?(/\A\d{4}-\d{2}-\d{2}\z/)

      # Exclude taxonomy and archive pages.
      return false if %w[
        category
        page
        tag
        author
      ].include?(slug)

      true
    rescue URI::InvalidURIError
      false
    end

    # --------------------------------------------------
    # JSON-LD
    # --------------------------------------------------

    def extract_json_ld(document)
      candidates = []

      document.css('script[type="application/ld+json"]').each do |script|
        parsed = JSON.parse(script.text)

        objects = parsed.is_a?(Array) ? parsed : [parsed]

        objects.each do |object|
          next unless object.is_a?(Hash)

          graph = object['@graph']

          if graph.is_a?(Array)
            candidates.concat(graph.select { |item| item.is_a?(Hash) })
          else
            candidates << object
          end
        end
      rescue JSON::ParserError
        next
      end

      # Prefer useful structured data instead of accidentally
      # returning a WebSite or BreadcrumbList object.
      preferred_types = %w[
        Event
        Course
        LearningResource
        HowTo
        VideoObject
        CreativeWork
      ]

      candidates.find do |candidate|
        types = Array(candidate['@type'])
        (types & preferred_types).any?
      end || candidates.first || {}
    end

    # --------------------------------------------------
    # Materials
    # --------------------------------------------------

    def extract_resource(document, source_url, metadata = {})
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
        document.at_css('main article p, main p')&.text

      return nil if clean(title).empty?

      {
        title: clean(title),
        description: clean(description),
        url: canonical_url(document, source_url),
        provider: PROVIDER_NAME,
        resource_type: infer_resource_type(document, source_url, metadata),
        keywords: extract_keywords(document, metadata)
      }
    end

    def extract_linked_resources(document, page_url)
      records = []

      document.css('a[href]').each do |anchor|
        url = absolute_url_for(anchor['href'], page_url)

        next unless url

        uri = URI.parse(url)

        extension = File.extname(uri.path)
                        .delete_prefix('.')
                        .downcase

        title = clean(anchor.text)

        # ------------------------------------------
        # Linked documents and media
        # ------------------------------------------

        if FILE_EXTENSIONS.include?(extension)

          if title.empty?
            title = File.basename(uri.path)
                        .tr('_-', ' ')
                        .sub(/\.[^.]+$/, '')
          end

          records << {
            title: title,
            description: "Learning material linked from EOSC Academy: #{page_url}",
            url: url,
            provider: PROVIDER_NAME,
            resource_type: infer_file_type(extension),
            keywords: %w[EOSC Academy training]
          }

          next
        end

        # ------------------------------------------
        # External learning resources
        # ------------------------------------------

        next unless external_learning_resource?(url, title)

        records << {
          title: title,
          description: 'Learning resource linked from EOSC Academy.',
          url: url,
          provider: PROVIDER_NAME,
          resource_type: 'learning_resource',
          keywords: %w[EOSC Academy training]
        }
      rescue URI::InvalidURIError
        next
      end

      records
    end

    def external_learning_resource?(url, title)
      uri = URI.parse(url)

      return false unless uri.scheme == 'https'

      return false if EOSC_HOSTS.include?(uri.host)

      return false if title.empty?

      title.match?(
        /training|tutorial|learning|course|presentation|slides|webinar|recording|handbook|module|video/i
      ) || url.match?(
        /zenodo\.org|youtube\.com|youtu\.be|vimeo\.com|github\.com/i
      )
    rescue URI::InvalidURIError
      false
    end

    def infer_resource_type(document, url, metadata = {})
      path = URI.parse(url).path.downcase

      return 'video' if path.match?(/\.(mp4|webm|mov)$/)
      return 'presentation' if path.match?(/\.(ppt|pptx|odp)$/)
      return 'document' if path.match?(/\.(pdf|doc|docx|odt)$/)

      types = Array(metadata['@type'])

      return 'course' if types.include?('Course')
      return 'video' if types.include?('VideoObject')

      og_type = meta_content(
        document,
        'meta[property="og:type"]'
      )

      return 'video' if og_type.to_s.include?('video')

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

    def extract_keywords(document, metadata)
      values = []

      raw = metadata['keywords']

      values.concat(
        raw.is_a?(Array) ? raw : raw.to_s.split(',')
      )

      values.concat(
        meta_content(document, 'meta[name="keywords"]').to_s.split(',')
      )

      values.concat(
        %w[
          EOSC
          EOSC-Academy
          EOSC-Federation
          training
          research-data-management
          open-science
          learning
        ]
      )

      values.map { |value| clean(value) }
            .reject(&:empty?)
            .uniq
    end

    # --------------------------------------------------
    # Academy material page detection
    # --------------------------------------------------

    def academy_material_page?(url, metadata)
      uri = URI.parse(url)

      path = uri.path.downcase

      # Academy landing and detail pages.
      return true if path == '/academy'
      return true if path.start_with?('/academy/')

      # Do not treat event pages as materials just because
      # they contain structured metadata.
      return false if path == '/events'
      return false if path.start_with?('/events/')

      types = Array(metadata['@type'])

      (
        types & %w[
          Course
          LearningResource
          VideoObject
          HowTo
        ]
      ).any?
    rescue URI::InvalidURIError
      false
    end

    # --------------------------------------------------
    # Events
    # --------------------------------------------------

    def extract_event(document, source_url, metadata)
      title =
        metadata['name'] ||
        metadata['headline'] ||
        document.at_css('main h1')&.text ||
        document.at_css('h1')&.text

      return nil if clean(title).empty?

      start_value = metadata['startDate']
      end_value = metadata['endDate']

      # HTML fallback for event pages without JSON-LD.
      start_value ||= extract_date(
        document,
        [
          'time[datetime]',
          '.event-date',
          '.field--name-field-date',
          '.event-start-date'
        ]
      )

      start_date = parse_date(start_value)
      end_date = parse_date(end_value)

      # Events without a valid start date are not ingested.
      return nil unless start_date

      description =
        metadata['description'] ||
        document.at_css('main article p, main p')&.text

      {
        title: clean(title),
        description: clean(description),
        url: canonical_url(document, source_url),
        provider: PROVIDER_NAME,
        start: start_date,
        end: end_date,
        location: extract_location(metadata),
        keywords: %w[
          EOSC
          Academy
          event
          training
          webinar
        ]
      }
    end

    def extract_date(document, selectors)
      selectors.each do |selector|
        element = document.at_css(selector)

        next unless element

        datetime = element['datetime']

        return datetime if datetime.present?

        return clean(element.text)
      end

      nil
    end

    def parse_date(value)
      return nil if value.blank?

      if Time.zone
        Time.zone.parse(value.to_s)
      else
        Time.parse(value.to_s)
      end
    rescue ArgumentError, TypeError
      nil
    end

    def extract_location(metadata)
      location = metadata['location']

      return nil unless location

      if location.is_a?(Hash)
        location['name'] ||
          location.dig('address', 'addressLocality')
      else
        location.to_s
      end
    end

    # --------------------------------------------------
    # Event deduplication
    # --------------------------------------------------

    def add_event(record)
      return unless record.is_a?(Hash)
      return if record[:title].blank?
      return if record[:start].nil?
      return if record[:url].blank?

      # Defensive initialization.
      @event_keys ||= Set.new
      @event_urls ||= Set.new
      @events ||= []

      url = canonicalize_url(record[:url])
      return unless url

      fingerprint = [
        clean(record[:title]).downcase,
        record[:start].to_date
      ]

      # Check both keys before adding either one.
      # Set#add? returns nil for an existing value;
      # using include? makes the logic explicit.
      return if @event_urls.include?(url)
      return if @event_keys.include?(fingerprint)

      @event_urls.add(url)
      @event_keys.add(fingerprint)

      # Create an actual ActiveRecord Event object.
      event = Event.new(
        title: clean(record[:title]),
        description: clean(record[:description]),
        url: url,
        start: record[:start],
        end: record[:end],
        venue: clean(record[:location]),
        keywords: Array(record[:keywords])
      )

      # Store deduplication keys only after successfully building the event.
      @event_urls.add(url)
      @event_keys.add(fingerprint)

      @events << event

      Rails.logger.info(
        "[EOSC] Event: #{event[:title]}"
      )

      event
    end

    # --------------------------------------------------
    # Material creation
    # --------------------------------------------------

    def add_resource(record)
      return unless record.is_a?(Hash)
      return if record[:title].blank?
      return if record[:url].blank?

      @resource_urls ||= Set.new
      @resources ||= []
      @materials ||= []

      url = canonicalize_url(record[:url])

      return unless url
      return if @resource_urls.include?(url)

      @resource_urls.add(url)

      material = Material.new(
        title: clean(record[:title]),
        description: clean(record[:description]),
        url: url,
        resource_type: record[:resource_type],
        keywords: record[:keywords]
      )

      @resources << material
      @materials << material

      Rails.logger.info(
        "[EOSC] Material: #{material.title}"
      )

      material
    end

    # --------------------------------------------------
    # Helpers
    # --------------------------------------------------

    def canonical_url(document, fallback)
      href = document.at_css(
        'link[rel="canonical"]'
      )&.[]('href')

      return fallback if href.blank?

      absolute_url_for(href, fallback) || fallback
    end

    def canonicalize_url(url)
      absolute_url_for(url, LANDING_PAGE)
    end

    def absolute_url_for(href, base_url)
      return nil if href.to_s.strip.empty?

      uri = URI.join(base_url, href)

      return nil unless %w[http https].include?(uri.scheme)

      uri.fragment = nil
      uri.query = nil

      # Normalize the EOSC host.
      uri.host = EOSC_BASE_HOST if EOSC_HOSTS.include?(uri.host)

      # Normalize trailing slashes, except for the root.
      uri.path = uri.path.sub(%r{/+\z}, '') if uri.path.length > 1

      uri.to_s
    rescue URI::InvalidURIError
      nil
    end

    def meta_content(document, selector)
      document.at_css(selector)&.[]('content')
    end

    # --------------------------------------------------
    # Text cleanup
    # --------------------------------------------------

    def clean(value)
      text = Nokogiri::HTML.fragment(
        CGI.unescapeHTML(value.to_s)
      ).text

      text.gsub(/\s+/, ' ').strip
    end
  end
end
