require 'json'
require 'rest-client'
require 'uri'
require 'ostruct'
require 'nokogiri'
require 'date'

module Ingestors
  class HpcPortalIngestor < Ingestor
    HPC_PORTAL_BASE_URL = ENV.fetch(
      'HPC_PORTAL_BASE_URL',
      'https://hpc-portal.eu'
    ).chomp('/').freeze

    HPC_PORTAL_TRAINING_URL = "#{HPC_PORTAL_BASE_URL}/training".freeze
    HPC_PORTAL_EVENTS_URL = "#{HPC_PORTAL_BASE_URL}/news/events".freeze

    PROVIDER = 'HPC Portal'.freeze
    USER_AGENT = 'HPC Portal Ingestor'.freeze

    HPC_PORTAL_MAX_PAGES = ENV.fetch(
      'HPC_PORTAL_MAX_PAGES',
      '1500'
    ).to_i

    HPC_PORTAL_REQUEST_DELAY = ENV.fetch(
      'HPC_PORTAL_REQUEST_DELAY', '0.3'
    ).to_f

    HPC_PORTAL_INCLUDE_GENERAL_EVENTS = ENV.fetch(
      'HPC_PORTAL_INCLUDE_GENERAL_EVENTS', 'false'
    ) == 'true'

    TRACKING_PARAMETERS = %w[
      utm_source utm_medium utm_campaign utm_content utm_term
      fbclid gclid
    ].freeze

    NON_EVENT_TITLES = %w[
      material materials training events courses workshops
      pagination next previous next-page previous-page last-page
      user-account-menu account-menu log-in login register search menu
    ].freeze

    ASSET_EXTENSIONS =
      /\.(?:pdf|png|jpe?g|gif|svg|zip|docx?|xlsx?|pptx?|mp4|mp3)$/i

    LISTING_PATHS = %w[
      /training
      /training/short-courses
      /training/material
      /training/academic-programmes
      /training/study-modules
    ].freeze

    IGNORED_EVENT_TITLES = [
      'pagination', 'next', 'previous', 'next page', 'previous page',
      'last page', 'last', 'page 1', 'page 2'
    ].freeze

    def self.config
      {
        key: 'hpc_portal_ingestor',
        title: 'HPC Portal',
        category: :any,
        description: 'Ingestor for HPC Portal training courses, materials and events',
        parameters: {}
      }
    end

    def materials
      @materials || []
    end

    def events
      @events || []
    end

    # Reads training materials and events separately.
    def read(source_url = nil)
      start_url = source_url.presence || HPC_PORTAL_TRAINING_URL

      raise ArgumentError, "Invalid HPC Portal URL: #{start_url}" unless valid_crawl_url?(start_url)

      @materials = []
      @events = []

      visited = Set.new
      queued = Set.new
      material_urls = Set.new
      event_keys = Set.new

      first_url = canonical_url(start_url)
      queue = [first_url]
      queued.add(first_url)

      if HPC_PORTAL_INCLUDE_GENERAL_EVENTS &&
         canonical_url(start_url) == canonical_url(HPC_PORTAL_TRAINING_URL)
        events_url = canonical_url(HPC_PORTAL_EVENTS_URL)

        unless queued.include?(events_url)
          queue << events_url
          queued.add(events_url)
        end
      end

      pages_visited = 0
      detail_pages = 0
      events_discovered = 0
      courses_converted = 0

      Rails.logger.info("[HPC Portal] Start Harvesting: #{start_url}")

      until queue.empty? || pages_visited >= HPC_PORTAL_MAX_PAGES
        url = queue.shift
        next if visited.include?(url)

        visited.add(url)

        begin
          document = fetch_document(url)
          next unless document

          pages_visited += 1

          listing = listing_page?(url, document)

          # ---------------------------------------------------------
          # 1. Extract *EVENTS* from listing pages.
          # ---------------------------------------------------------
          if listing
            extract_listing_events(document, url).each do |event|
              unless event.is_a?(Hash)
                Rails.logger.warn(
                  "[HPC Portal] Skipping invalid event value: #{event.class}"
                )
                next
              end

              title = event[:title] || event['title']
              event_url = event[:url] || event['url']

              next if title.blank? || event_url.blank?
              next unless valid_crawl_url?(event_url)
              next if canonical_url(event_url) == canonical_url(url)

              key = event_key(event)
              next if key.blank? || key == '||'
              next if event_keys.include?(key)

              event_keys.add(key)
              add_event(event)
              events_discovered += 1
            end
          end

          # ---------------------------------------------------------
          # 2. Convert individual short-course pages into events.
          #
          # This runs independently of listing extraction, so a
          # detail page does not have to look like a listing card.
          # ---------------------------------------------------------
          if training_course_detail_page?(url)
            event = extract_short_course_event(document, url)

            if event.is_a?(Hash)
              title = event[:title] || event['title']
              event_url = event[:url] || event['url']

              if title.present? &&
                 event_url.present? &&
                 valid_crawl_url?(event_url)

                key = event_key(event)

                if key.present? && key != '||' &&
                   !event_keys.include?(key)

                  event_keys.add(key)
                  add_event(event)
                  events_discovered += 1
                  courses_converted += 1

                else
                  Rails.logger.debug(
                    '[HPC Portal] Short course event already stored: ' \
                    "#{title.inspect} (#{event_url})"
                  )
                end
              else
                Rails.logger.warn(
                  '[HPC Portal] Short-course conversion returned an ' \
                  "invalid title or URL: #{url}"
                )
              end
            end
          end

          # ---------------------------------------------------------
          # 3. Preserve the existing material extraction workflow.
          # Short-course pages may be stored as both events and
          # learning materials.
          # ---------------------------------------------------------
          if detail_page?(document, url)
            detail_pages += 1
            material = extract_material(document, url)

            if material.is_a?(Hash)
              material_url = material[:url] || material['url'] || url
              canonical = canonical_url(material_url)

              unless material_urls.include?(canonical)
                material_urls.add(canonical)
                add_material(material)
              end
            end
          end

          # ---------------------------------------------------------
          # 4. Discover more training pages.
          # ---------------------------------------------------------
          training_links(document, url).each do |link|
            next unless valid_crawl_url?(link)

            canonical = canonical_url(link)

            next if visited.include?(canonical)
            next if queued.include?(canonical)
            next if visited.size + queue.size >= HPC_PORTAL_MAX_PAGES

            queue << canonical
            queued.add(canonical)
          end
        rescue RestClient::ExceptionWithResponse => e
          Rails.logger.warn(
            "[HPC Portal] HTTP error for #{url} #{e.message}"
          )
        rescue RestClient::Exception => e
          Rails.logger.warn(
            "[HPC Portal] Request failed for #{url} #{e.class}: #{e.message}"
          )
        rescue StandardError => e
          Rails.logger.error(
            "[HPC Portal] Failed to harvest #{url} " \
            "#{e.class}: #{e.message}\n#{e.backtrace&.first(10)&.join("\n")}"
          )
        ensure
          sleep(HPC_PORTAL_REQUEST_DELAY) if HPC_PORTAL_REQUEST_DELAY.positive?
        end
      end

      if queue.any?
        Rails.logger.warn(
          '[HPC Portal] Maximum page limit reached ' \
          "(#{HPC_PORTAL_MAX_PAGES}). #{queue.size} URLs remain queued."
        )
      end

      @materials = sort_materials_by_date(@materials)

      Rails.logger.info('[HPC Portal] ========== Summary Report ==========')
      Rails.logger.info("[HPC Portal] Pages visited: #{pages_visited}")
      Rails.logger.info("[HPC Portal] Events discovered: #{events_discovered}")
      Rails.logger.info("[HPC Portal] Short courses converted: #{courses_converted}")
      Rails.logger.info("[HPC Portal] Unique events discovered: #{@events.size}")
      Rails.logger.info("[HPC Portal] Materials discovered: #{@materials.size}")
      Rails.logger.info('[HPC Portal] =====================================')

      {
        materials: @materials,
        events: @events
      }
    rescue StandardError => e
      Rails.logger.error(
        "HpcPortalIngestor failed: #{e.class}: #{e.message}\n" \
        "#{e.backtrace&.first(10)&.join("\n")}"
      )
      raise
    end

    # Keep the existing Rails material-processing workflow.
    def add_material(material)
      if material.is_a?(Hash)
        controller = MaterialsController.new
        controller.params = { material: material }

        material = OpenStruct.new(controller.send(:material_params))
      end

      material = handle_auto_parsing(material)
      material = handle_controlled_vocabulary(material)

      @materials << material unless material.nil?
    end

    private

    # ---------------------------------------------------------------
    # HTTP
    # ---------------------------------------------------------------
    def fetch_document(url)
      response = RestClient::Request.execute(
        method: :get,
        url: url,
        headers: {
          accept: 'text/html,application/xhtml+xml',
          user_agent: USER_AGENT
        },
        open_timeout: 10,
        read_timeout: 25,
        max_redirects: 5
      )

      content_type = response.headers[:content_type].to_s

      unless content_type.empty? ||
             content_type.match?(%r{text/html|application/xhtml\+xml}i)
        Rails.logger.debug(
          "[HPC Portal] Skipping non-HTML response: #{url} (#{content_type})"
        )
        return nil
      end

      Nokogiri::HTML(response.body)
    end

    # ---------------------------------------------------------------
    # URL handling
    # ---------------------------------------------------------------
    def valid_crawl_url?(url)
      uri = URI.parse(url)

      %w[http https].include?(uri.scheme) &&
        allowed_host?(uri.host) &&
        crawlable_path?(uri.path)
    rescue URI::InvalidURIError, TypeError
      false
    end

    def valid_training_url?(url)
      uri = URI.parse(url)

      %w[http https].include?(uri.scheme) &&
        allowed_host?(uri.host) &&
        uri.path.to_s.start_with?('/training')
    rescue URI::InvalidURIError, TypeError
      false
    end

    def allowed_host?(host)
      %w[hpc-portal.eu www.hpc-portal.eu].include?(host.to_s.downcase)
    end

    def crawlable_path?(path)
      path.to_s.start_with?('/training') ||
        (
          HPC_PORTAL_INCLUDE_GENERAL_EVENTS &&
          path.to_s.start_with?('/news/events')
        )
    end

    def canonical_url(url)
      uri = URI.join("#{HPC_PORTAL_BASE_URL}/", url.to_s)

      uri.fragment = nil

      if uri.query
        parameters = URI.decode_www_form(uri.query)

        parameters.reject! do |key, _value|
          TRACKING_PARAMETERS.include?(key.downcase)
        end

        parameters.sort!
        uri.query = parameters.empty? ? nil : URI.encode_www_form(parameters)
      end

      uri.path = '/' if uri.path.empty?
      uri.path = uri.path.sub(%r{/$}, '') if uri.path != '/'

      uri.to_s
    end

    # ---------------------------------------------------------------
    # Link discovery and page classification
    # ---------------------------------------------------------------
    def training_links(document, page_url)
      document.css('a[href]').filter_map do |anchor|
        href = anchor['href'].to_s.strip

        next if href.empty?
        next if href.start_with?('#', 'mailto:', 'javascript:', 'tel:', 'data:')

        begin
          uri = URI.join(page_url, href)

          next unless %w[http https].include?(uri.scheme)
          next unless allowed_host?(uri.host)
          next unless crawlable_path?(uri.path)
          next if uri.path.match?(ASSET_EXTENSIONS)

          canonical_url(uri.to_s)
        rescue URI::InvalidURIError, URI::BadURIError
          nil
        end
      end.uniq
    end

    def listing_page?(url, document)
      path = URI.parse(url).path
      normalized_path = path.sub(%r{/$}, '')

      return true if LISTING_PATHS.include?(normalized_path)

      if HPC_PORTAL_INCLUDE_GENERAL_EVENTS &&
         normalized_path == '/news/events'
        return true
      end

      # Do not classify individual training detail pages as listings.
      return false if normalized_path.match?(
        %r{\A/training/(?:short-courses|material|academic-programmes|study-modules)/.+}
      )

      headings = document.css('main h2, main h3, article h2, article h3')

      headings.length >= 3 &&
        document.css('main a[href], article a[href]').length >= 3
    rescue URI::InvalidURIError
      false
    end

    def detail_page?(document, url)
      path = URI.parse(url).path.sub(%r{/$}, '')

      return false if LISTING_PATHS.include?(path)

      if HPC_PORTAL_INCLUDE_GENERAL_EVENTS &&
         path.start_with?('/news/events')
        return false
      end

      heading = document.at_css(
        'main h1, article h1, .region-content h1, h1'
      )

      return false unless heading

      title = clean_text(heading.text)
      return false if title.empty?

      listing_titles = [
        'training',
        'short courses',
        'training material',
        'training materials',
        'academic programmes',
        'academic programs',
        'study modules',
        'events',
        'pagination'
      ]

      !listing_titles.include?(title.downcase)
    rescue URI::InvalidURIError
      false
    end

    # Match a single short-course detail URL, not the listing itself.
    def short_course_detail_page?(url)
      path = URI.parse(url).path.sub(%r{/$}, '')

      path.match?(
        %r{\A/training/short-courses/[^/]+\z}
      )
    rescue URI::InvalidURIError, TypeError
      false
    end

    # ---------------------------------------------------------------
    # Pagination detection
    # ---------------------------------------------------------------
    def pagination_element?(node)
      return false unless node

      is_pagination_node = lambda do |element|
        next false unless element.element?

        tag = element.name.to_s.downcase
        classes = element['class'].to_s.downcase
        role = element['role'].to_s.downcase
        aria_label = element['aria-label'].to_s.downcase

        tag == 'nav' ||
          classes.split.any? { |name| name.include?('pagination') } ||
          role == 'navigation' ||
          aria_label.include?('pagination')
      end

      return true if is_pagination_node.call(node)

      node.ancestors.any? do |ancestor|
        is_pagination_node.call(ancestor)
      end
    end

    # ---------------------------------------------------------------
    # Event extraction from listing pages
    # ---------------------------------------------------------------
    def extract_listing_events(document, page_url)
      selectors = [
        '.event-card',
        '.event-item',
        '.event-teaser',
        '.webinar-card',
        '.workshop-card',
        '.course-card',
        '.views-row',
        '.node--type-course',
        '.node--type-event',
        'main .card',
        '.region-content .card',
        'main article',
        '.region-content article',
        'main li',
        '.region-content li'
      ]

      cards = []

      selectors.each do |selector|
        matches = document.css(selector).reject do |node|
          pagination_element?(node)
        end

        next if matches.empty?

        cards = matches
        break
      end

      if cards.empty?
        document.css(
          'main a[href], .region-content a[href], article a[href]'
        ).each do |anchor|
          next if pagination_element?(anchor)

          href = anchor['href'].to_s.strip
          next if href.blank?
          next if href.start_with?(
            '#', 'javascript:', 'mailto:', 'tel:', 'data:'
          )

          heading = anchor.at_css('h1, h2, h3, h4') ||
                    anchor.ancestors('h1, h2, h3, h4').first

          heading ||= anchor.parent&.at_css('h1, h2, h3, h4')

          candidate = anchor.ancestors.find do |ancestor|
            %w[article li].include?(ancestor.name) ||
              ancestor['class'].to_s.match?(
                /card|event|course|webinar|workshop|views-row|node--type/i
              )
          end

          candidate ||= anchor.parent

          next unless candidate
          next if pagination_element?(candidate)
          next unless heading || clean_text(anchor.text).present?

          cards << candidate unless cards.any? { |existing| existing == candidate }
        end
      end

      cards = cards.uniq
      cards.reject! do |card|
        cards.any? do |other|
          !other.equal?(card) && other.ancestors.include?(card)
        end
      end

      events = cards.filter_map do |card|
        event = extract_listing_event(card, page_url)

        unless event.is_a?(Hash)
          Rails.logger.debug(
            '[HPC Portal] Candidate rejected: ' \
            "#{clean_text(card.text)[0, 200].inspect}"
          )
          next
        end

        event
      rescue StandardError => e
        Rails.logger.warn(
          '[HPC Portal] Failed to extract candidate: ' \
          "#{e.class}: #{e.message} (URL=#{page_url})"
        )
        nil
      end

      seen = Set.new
      events.select do |event|
        key = event_key(event)
        key.present? && seen.add?(key)
      end
    end

    def extract_listing_event(card, page_url)
      return nil unless card&.element?
      return nil if pagination_element?(card)

      heading = card.at_css(
        'h1, h2, h3, h4, .card-title, .course-title, .event-title'
      )

      return nil unless heading

      title = clean_text(heading.text)
      normalized_title = title.downcase.gsub(/\s+/, ' ')

      ignored_titles =
        NON_EVENT_TITLES.map { |value| value.downcase.gsub(/\s+/, ' ') } +
        IGNORED_EVENT_TITLES

      if title.blank? || ignored_titles.include?(normalized_title)
        Rails.logger.debug(
          "[HPC Portal] Skipping generic listing heading: #{title.inspect}"
        )
        return nil
      end

      link = if heading.name.to_s.downcase == 'a'
               heading
             else
               heading.at_css('a[href]') || heading.ancestors('a[href]').first
             end

      link ||= card.css('a[href]').find do |anchor|
        next false if pagination_element?(anchor)

        href = anchor['href'].to_s.strip
        label = clean_text(anchor.text)

        href.present? &&
          !href.start_with?('#', 'javascript:', 'mailto:', 'tel:', 'data:') &&
          !label.match?(
            /\A(next|previous|prev|next page|previous page|last page|read more)\z/i
          )
      end

      return nil unless link

      href = link['href'].to_s.strip
      return nil if href.blank? || href.start_with?(
        '#', 'javascript:', 'mailto:', 'tel:', 'data:'
      )

      event_url = URI.join(page_url, href).to_s

      return nil unless valid_crawl_url?(event_url)
      return nil if canonical_url(event_url) == canonical_url(page_url)

      event_uri = URI.parse(event_url)
      return nil if event_uri.path.match?(ASSET_EXTENSIONS)

      clean_card = card.dup
      clean_card.css(
        'script, style, noscript, nav, header, footer, form, ' \
        '[role="navigation"], .breadcrumb, .breadcrumbs, .pagination, ' \
        '[class*="pagination"]'
      ).remove

      # Preserve formatting for the event description
      description = extract_markdown_blocks(clean_card)
      # return nil if description.blank?
      description ||= ''

      # Use plain text for event metadata and classification
      text = clean_text(clean_card.text)
      return nil if text.blank?

      metadata = extract_event_metadata_from_text(text)
      registration_url = extract_registration_url(clean_card, page_url)

      card_class = card['class'].to_s
      parent_class = card.parent&.[]('class').to_s

      event_class_signal = (card_class + ' ' + parent_class).match?(
        /(?:^|[\s_-])(event|event-card|event-item|course|course-card|webinar|workshop)(?:$|[\s_-])/i
      )

      event_url_signal = event_uri.path.match?(
        %r{/(?:events?|webinars?|workshops?|conferences?|short-courses|courses)(?:/|$)}i
      )

      title_signal = title.match?(
        /\b(event|webinar|workshop|conference|course|training|summer school|tutorial)\b/i
      )

      registration_signal = registration_url.present?

      listing_path = URI.parse(page_url).path.sub(%r{/$}, '')

      training_listing_signal = %w[
        /training/short-courses
        /training/academic-programmes
        /training/study-modules
      ].include?(listing_path)

      unless event_class_signal ||
             event_url_signal ||
             title_signal ||
             registration_signal ||
             training_listing_signal
        Rails.logger.debug(
          "[HPC Portal] Skipping #{title.inspect}: no event-specific signal; " \
          "card_class=#{card_class.inspect}, " \
          "parent_class=#{parent_class.inspect}, " \
          "event_url=#{event_url.inspect}, page_url=#{page_url}"
        )
        return nil
      end

      event = {
        title: title,
        url: canonical_url(event_url),
        description: description,
        registration: registration_url,
        related_links: extract_related_links(clean_card, page_url)
      }.merge(metadata).compact

      log_event_details(event)
      event
    rescue URI::InvalidURIError, URI::BadURIError => e
      Rails.logger.warn(
        "[HPC Portal] Invalid event URL on #{page_url}: #{e.message}"
      )
      nil
    end

    # ---------------------------------------------------------------
    # NEW: Convert a short-course detail page into an event.
    # ---------------------------------------------------------------
    def extract_short_course_event(document, page_url)
      title = clean_text(document.at_css('h1')&.text)
      return if title.empty?

      clean_content = document.at_css('main, article, .region-content, .content')
      clean_content ||= document

      clean_content = clean_content.dup
      clean_content.css(
        'script, style, nav, header, footer, aside, ' \
        '.breadcrumb, .breadcrumbs, .menu, .tabs, ' \
        '.share, .social, .related-content'
      ).remove

      # Remove the page title so it is not duplicated in the description.
      first_heading = clean_content.at_css('h1')
      first_heading.remove if first_heading

      # Markdown description preserves the original content structure.
      description = extract_markdown_blocks(clean_content)
      description = description[0, 5000] if description.present?
      description = nil if description.blank?

      # Plain text is still used for metadata extraction.
      metadata_text = clean_text(clean_content.text)

      # Extract metadata from the visible course text.
      metadata = extract_event_metadata_from_text(
        "#{title} #{metadata_text}"
      ) || {}

      # Prefer structured date values from HTML <time> elements.
      time_values = clean_content.css('time').filter_map do |node|
        value = node['datetime'].to_s.strip
        value = clean_text(node.text) if value.empty?
        value unless value.empty?
      end

      structured_dates = time_values
                         .flat_map { |value| extract_event_dates(value) }
                         .compact
                         .uniq
                         .sort

      if structured_dates.any?
        metadata[:start_date] = structured_dates.first.iso8601
        metadata[:end_date] =
          structured_dates.length > 1 ? structured_dates.last.iso8601 : nil
      end

      registration_url = extract_registration_url(clean_content, page_url)

      related_links = clean_content.css('a[href]').filter_map do |link|
        href = link['href'].to_s.strip
        text = clean_text(link.text)

        next if href.empty? || text.empty?

        absolute_url = URI.join(page_url, href).to_s
        next if absolute_url == canonical_url(page_url)

        {
          title: text,
          url: absolute_url
        }
      rescue URI::InvalidURIError
        nil
      end.uniq { |link| link[:url] }

      event = {
        title: title,
        url: canonical_url(page_url),
        description: description,
        registration: registration_url,
        related_links: related_links
      }.merge(metadata).compact

      Rails.logger.info('[>>Event<<]')
      log_event_details(event)

      event
    rescue StandardError => e
      Rails.logger.error(
        "[HPC Portal] Failed to convert short course #{page_url}: " \
        "#{e.class}: #{e.message}"
      )
      nil
    end

    def event_key(event)
      return nil unless event.is_a?(Hash)

      url = event[:url] || event['url']
      title = event[:title] || event['title']
      date = event[:start_date] || event['start_date']

      if url.present?
        canonical_url(url).downcase
      elsif title.present?
        "#{title.to_s.downcase.strip}|#{date}"
      end
    rescue URI::InvalidURIError, URI::BadURIError
      nil
    end

    def log_event_details(event)
      Rails.logger.info(
        <<~LOG
          --------------------------------------------------------------------------------------
          [HPC Portal] Event found
            Title:        #{event[:title] || 'Unknown'}
            Start date:   #{event[:start_date] || 'Unknown'}
            End date:     #{event[:end_date] || 'Unknown'}
            Location:     #{event[:location] || 'Unknown'}
            Delivery:     #{event[:event_mode] || 'Unknown'}
            Language:     #{event[:language] || 'Unknown'}
            Event URL:    #{event[:url] || 'Unknown'}
            Registration: #{event[:registration] || 'Not available'}
            Description:  #{event[:description].to_s.truncate(100).presence || 'Not available'}
          --------------------------------------------------------------------------------------
        LOG
      )
    end

    def extract_event_metadata_from_text(text)
      {
        start_date: extract_start_date(text),
        end_date: extract_end_date(text),
        event_mode: extract_event_mode(text),
        location: extract_event_location(text),
        language: extract_language(text)
      }.compact
    end

    # ---------------------------------------------------------------
    # Material extraction
    # ---------------------------------------------------------------
    def extract_material(document, url)
      heading = document.at_css(
        'main h1, article h1, .region-content h1, h1'
      )

      return nil unless heading

      title = clean_text(heading.text)
      return nil if title.empty?
      return nil if IGNORED_EVENT_TITLES.include?(title.downcase)

      content = document.at_css(
        'main, article, .region-content, .content'
      ) || document.at_css('body')

      return nil unless content

      content = content.dup
      content.css(
        'nav, header, footer, script, style, form, aside, ' \
        '.breadcrumb, .breadcrumbs, .sidebar, .menu, ' \
        '.pagination, [class*="pagination"]'
      ).remove

      # Remove the page title from the description content
      first_heading = content.at_css('h1')
      first_heading.remove if first_heading

      description = extract_markdown_blocks(content)
      description = description[0, 5000] if description.present?

      text = "#{title} #{description}"

      material = {
        title: title,
        description: description.presence ||
                     "#{title} — training resource from HPC Portal.",
        url: url,
        provider: PROVIDER,
        keywords: extract_keywords(text),
        target_audience: [
          'Researchers',
          'HPC Developers',
          'Software Engineers'
        ],
        status: :active,
        material_type: infer_material_type(url, text),
        licence: extract_licence(content),
        language: extract_language(text),
        learning_resource_type: 'Training',
        source: PROVIDER,
        source_url: url
      }.compact

      Rails.logger.info('[>>Course<<]')
      log_material_details(material)

      material
    end

    def extract_markdown_blocks(content)
      blocks = content.children.filter_map do |node|
        markdown_for_node(node)
      end

      blocks.reject(&:blank?).join("\n\n").strip
    end

    def markdown_for_node(node)
      return '' unless node.element?

      case node.name
      when 'h2', 'h3', 'h4'
        level = node.name[1].to_i
        "#{'#' * level} #{clean_text(node.text)}"
      when 'p'
        inline_markdown(node).strip
      when 'ul', 'ol'
        ordered = node.name == 'ol'

        items = node.element_children
                    .select { |child| child.name == 'li' }
                    .each_with_index.map do |item, index|
          marker = ordered ? "#{index + 1}." : '-'
          "#{marker} #{inline_markdown(item).strip}"
        end
        items.join("\n")

      when 'blockquote'
        inline_markdown(node).strip
                             .lines
                             .map { |line| "> #{line.strip}" }
                             .join("\n")
      when 'div', 'section', 'article', 'main'
        extract_markdown_blocks(node)
      when 'pre'
        "```\n#{node.text.strip}\n```"
      else
        inline_markdown(node).strip
      end
    end

    def inline_markdown(node)
      node.children.map do |child|
        if child.text?
          child.text.gsub(/[\u00A0\u2007\u202F]/, ' ')
        elsif child.element?
          text = inline_markdown(child)

          case child.name
          when 'strong', 'b'
            "**#{text.strip}**"
          when 'em', 'i'
            "*#{text.strip}*"
          when 'code'
            "`#{text.strip}`"
          when 'a'
            href = child['href'].to_s.strip

            if href.present? &&
               !href.start_with?('javascript:', 'data:')
              "[#{text.strip}](#{href})"
            else
              text
            end
          when 'br'
            "\n"
          else
            text
          end
        else
          ''
        end
      end.join.gsub(/[ \t]+/, ' ').strip
    end

    def extract_related_links(content, page_url)
      content.css('a[href]').filter_map do |anchor|
        next if pagination_element?(anchor)

        href = anchor['href'].to_s.strip
        label = clean_text(anchor.text)

        next if href.empty? || label.empty?
        next if href.start_with?('#', 'mailto:', 'javascript:', 'tel:', 'data:')

        begin
          absolute_url = URI.join(page_url, href)
          next unless %w[http https].include?(absolute_url.scheme)

          {
            name: label[0, 250],
            url: absolute_url.to_s
          }
        rescue URI::InvalidURIError, URI::BadURIError
          nil
        end
      end.uniq { |link| link[:url] }
    end

    # ---------------------------------------------------------------
    # Date extraction
    # ---------------------------------------------------------------
    def extract_start_date(text)
      extract_event_dates(text).first&.iso8601
    end

    def extract_end_date(text)
      dates = extract_event_dates(text)
      dates.length > 1 ? dates.last.iso8601 : nil
    end

    def extract_event_dates(text)
      text = text.to_s
      dates = []

      # ISO dates: 2026-12-08
      text.scan(/\b(\d{4})-(\d{2})-(\d{2})\b/) do |year, month, day|
        safely_add_date(dates, year.to_i, month.to_i, day.to_i)
      end

      # European numeric dates: 08/12/2026 or 08.12.2026
      text.scan(%r{\b(\d{1,2})[/.](\d{1,2})[/.](\d{4})\b}) do |day, month, year|
        safely_add_date(dates, year.to_i, month.to_i, day.to_i)
      end

      # European dates with hyphens: 08-12-2026
      text.scan(/\b(\d{1,2})-(\d{1,2})-(\d{4})\b/) do |day, month, year|
        safely_add_date(dates, year.to_i, month.to_i, day.to_i)
      end

      # English month names: December 8, 2026
      text.scan(
        /\b(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2}),?\s+(\d{4})\b/i
      ) do |month_name, day, year|
        dates << Date.parse("#{month_name} #{day}, #{year}")
      rescue Date::Error, ArgumentError
        next
      end

      # European month names: 8 December 2026
      text.scan(
        /\b(\d{1,2})\s+(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{4})\b/i
      ) do |day, month_name, year|
        dates << Date.parse("#{day} #{month_name} #{year}")
      rescue Date::Error, ArgumentError
        next
      end

      dates.uniq.sort
    end

    def safely_add_date(dates, year, month, day)
      dates << Date.new(year, month, day)
    rescue Date::Error, ArgumentError
      nil
    end

    # ---------------------------------------------------------------
    # Event metadata
    # ---------------------------------------------------------------
    def extract_event_mode(text)
      return 'Online' if text.match?(/\bonline\b/i)
      return 'Hybrid' if text.match?(/\bhybrid\b/i)
      return 'In-person' if text.match?(/\bin[\s-]person\b/i)

      nil
    end

    def extract_event_location(text)
      match = text.to_s.match(
        /(?:location|venue|place|where)\s*:\s*([^|;\n]{2,150})/i
      )

      clean_text(match[1]) if match
    end

    def extract_registration_url(content, page_url)
      content.css('a[href]').each do |anchor|
        next if pagination_element?(anchor)

        label = clean_text(anchor.text)
        href = anchor['href'].to_s.strip
        next if href.empty?

        registration_label = label.match?(
          /\b(register|registration|sign up|apply|enrol|enroll|book your place)\b/i
        )

        registration_href = href.match?(
          /register|registration|signup|sign-up|enrol|enroll/i
        )

        next unless registration_label || registration_href

        begin
          uri = URI.join(page_url, href)
          return uri.to_s if %w[http https].include?(uri.scheme)
        rescue URI::InvalidURIError, URI::BadURIError
          next
        end
      end

      nil
    end

    # ---------------------------------------------------------------
    # Shared helpers
    # ---------------------------------------------------------------
    def clean_text(text)
      text.to_s
          .gsub(/[\u00A0\u2007\u202F]/, ' ')
          .gsub(/[[:space:]]+/, ' ')
          .strip
    end

    def extract_keywords(text)
      terms = [
        'HPC', 'EuroHPC', 'GPU', 'CPU', 'MPI', 'OpenMP',
        'CUDA', 'Python', 'Linux', 'Slurm', 'AI',
        'Machine Learning', 'Deep Learning', 'Quantum Computing'
      ]

      terms.select do |term|
        text.match?(/\b#{Regexp.escape(term)}\b/i)
      end.unshift('High-performance computing').uniq
    end

    def infer_material_type(url, text)
      path = URI.parse(url).path.downcase

      return 'Course' if path.include?('short-courses')
      return 'Online course' if text.match?(/\bonline course\b/i)

      return 'Hands-on tutorial' if text.match?(/\b(hands-on|tutorial|practical)\b/i)
      return 'Training material' if path.include?('material')

      'Training resource'
    rescue URI::InvalidURIError
      'Training resource'
    end

    def extract_licence(content)
      text = clean_text(content.text)

      match = text.match(
        /\b(CC[- ]BY(?:[- ](?:SA|NC|ND))?(?:[- ]\d(?:\.\d)?)?|MIT License|Apache License 2\.0|GPL(?:v\d)?|BSD License)\b/i
      )

      match && match[0]
    end

    def extract_language(text)
      text = text.to_s

      # Return ISO 639-1 codes accepted by the TeSS language vocabulary.
      language_patterns = {
        'en' => /\benglish\b/i,
        'fr' => /\bfrench\b/i,
        'de' => /\bgerman\b/i,
        'es' => /\bspanish\b/i,
        'nl' => /\bdutch\b/i,
        'bg' => /\bbulgarian\b/i,
        'hr' => /\bcroatian\b/i,
        'cs' => /\bczech\b/i,
        'da' => /\bdanish\b/i,
        'et' => /\bestonian\b/i,
        'fi' => /\bfinnish\b/i,
        'el' => /\bgreek\b/i,
        'hu' => /\bhungarian\b/i,
        'ga' => /\birish\b/i,
        'it' => /\bitalian\b/i,
        'lv' => /\blatvian\b/i,
        'lt' => /\blithuanian\b/i,
        'mt' => /\bmaltese\b/i,
        'pl' => /\bpolish\b/i,
        'pt' => /\bportuguese\b/i,
        'ro' => /\bromanian\b/i,
        'sk' => /\bslovak\b/i,
        'sl' => /\bslovenian\b/i,
        'sv' => /\bswedish\b/i
      }

      # Prefer an explicit language-of-instruction label when present.
      labelled = text.match(
        /(?:language of instruction|language|taught in)\s*[:-]\s*([a-z]+)/i
      )

      candidate = labelled ? labelled[1] : text

      language_patterns.each do |code, pattern|
        return code if candidate.match?(pattern)
      end

      nil
    end

    # ---------------------------------------------------------------
    # Material sorting
    # ---------------------------------------------------------------
    def sort_materials_by_date(materials)
      materials.sort_by do |material|
        date = material.start_date if material.respond_to?(:start_date)

        date ||= extract_date_from_description(
          material.respond_to?(:description) ? material.description : nil
        )

        parsed_date = parse_sort_date(date)

        [
          parsed_date.nil? ? 1 : 0,
          parsed_date || Date.new(9999, 12, 31),
          material.respond_to?(:title) ? material.title.to_s.downcase : ''
        ]
      end
    end

    def extract_date_from_description(description)
      return nil if description.blank?

      extract_event_dates(description).first
    end

    def parse_sort_date(value)
      return nil if value.blank?

      Date.parse(value.to_s)
    rescue Date::Error, ArgumentError
      nil
    end

    def training_course_detail_page?(url)
      path = URI.parse(url).path.sub(%r{/$}, '')

      # Individual short-course pages.
      return true if path.match?(
        %r{\A/training/short-courses/[^/]+\z}
      )

      # Individual training-baseline courses, excluding the index page.
      return true if path.match?(
        %r{\A/training_baseline/(?!training-baseline\z)[^/]+\z}
      )

      false
    rescue URI::InvalidURIError, TypeError
      false
    end

    def log_material_details(material)
      Rails.logger.info(
        <<~LOG
          [HPC Portal] Course details...
            Title:        #{material[:title] || 'Unknown'}
            URL:          #{material[:url] || 'Unknown'}
            Provider:     #{material[:provider] || 'Unknown'}
            Keywords:     #{material[:keywords] || 'Unknown'}
            Audience:     #{material[:target_audience] || 'Unknown'}
            Status:       #{material[:status] || 'Unknown'}
            Type:         #{material[:material_type] || 'Unknown'}
          ---------------------------------------------------------------------------
        LOG
      )
    end
  end
end
