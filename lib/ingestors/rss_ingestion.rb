module Ingestors
  module RSSIngestion
    include DublinCoreIngestion

    # Fetches and parses a feed from the URL, with optional HTML feed discovery.
    # Returns [feed, parsed_content] on success, where parsed_content is the XML/Atom string used.
    # Returns [nil, nil] when the URL cannot be opened or parsing/discovery fails.
    def fetch_feed(url)
      io = open_url(url)
      return [nil, nil] if io.nil?

      content = io.read
      feed, parse_error_message = parse_feed(content)
      return [feed, content] unless feed.nil?

      discovered_feed_url = discover_feed_url_from_html(content, url)
      if discovered_feed_url.blank?
        @messages << parse_error_message
        return [nil, nil]
      end

      @messages << "HTML page detected, following feed link: #{discovered_feed_url}"
      discovered_io = open_url(discovered_feed_url)
      return [nil, nil] if discovered_io.nil?

      discovered_content = discovered_io.read
      discovered_feed, discovered_parse_error_message = parse_feed(discovered_content)
      if discovered_feed.blank?
        @messages << discovered_parse_error_message
        return [nil, nil]
      end

      [discovered_feed, discovered_content]
    end

    def parse_feed(content)
      feed = RSS::Parser.parse(content, { validate: false })
      return [feed, nil] if feed.present?

      [nil, 'parsing feed failed with: unrecognized feed content']
    rescue RSS::NotWellFormedError => e
      [nil, "parsing feed failed with: #{e.message}"]
    end

    def discover_feed_url_from_html(content, base_url)
      doc = Nokogiri::HTML(content)
      link = doc.css('link[rel]').find do |node|
        rel = node['rel'].to_s.downcase
        type = node['type'].to_s.downcase
        rel.include?('alternate') && (type.include?('rss') || type.include?('atom'))
      end

      href = link&.[]('href')
      return nil if href.blank?

      URI.join(base_url, href).to_s
    rescue StandardError
      nil
    end

    def feed_title(feed)
      channel = feed.respond_to?(:channel) ? feed.channel : nil
      return channel.title if channel.present? && channel.respond_to?(:title)
      return text_value(feed.title) if feed.respond_to?(:title)

      'Untitled feed'
    end

    alias text_value dublin_core_text

    def parse_time(value)
      value = value.content if value.respond_to?(:content)

      return value if value.is_a?(Time) || value.is_a?(Date) || value.is_a?(DateTime)

      text = text_value(value)
      return nil if text.blank?

      Time.zone.parse(text)
    rescue ArgumentError
      nil
    end

    def extract_dublin_core(item)
      {
        title: text_value(item.dc_title),
        description: text_value(item.dc_description),
        creators: Array(item.dc_creators),
        contributors: Array(item.dc_contributors),
        rights: Array(item.dc_rights_list),
        dates: Array(item.dc_dates),
        identifiers: Array(item.dc_identifiers),
        subjects: Array(item.dc_subjects),
        types: Array(item.dc_types),
        publisher: item.dc_publisher
      }
    end

    def extract_rss_keywords(item)
      return [] unless item.respond_to?(:categories)

      Array(item.categories).map { |c| text_value(c.respond_to?(:content) ? c.content : c) }
    end

    def extract_atom_keywords(item)
      return [] unless item.respond_to?(:categories)

      Array(item.categories).map { |c| text_value(c.respond_to?(:term) ? c.term : c) }
    end

    def extract_atom_authors(item)
      Array(item.authors).map { |author| text_value(author.respond_to?(:name) ? author.name : author) }
    end

    def extract_atom_link(item)
      item.links.map { |l| text_value(l.href) }.find(&:present?)
    end

    def prefer_precise_time(existing_value, candidate_time)
      return existing_value if candidate_time.blank?
      return candidate_time if existing_value.blank?

      return candidate_time if existing_value.is_a?(Date) && !existing_value.is_a?(DateTime) && existing_value == candidate_time.to_date

      existing_value
    end

    def merge_unique(existing_values, new_values)
      normalize_dublin_core_values(Array(existing_values) + Array(new_values))
    end

    def merge_with_bioschemas_priority(bioschemas_records, rss_records)
      rss_by_url = rss_records.index_by { |record| record[:url].to_s }

      merged = bioschemas_records.map do |bioschemas_record|
        key = bioschemas_record[:url].to_s
        rss_record = rss_by_url.delete(key)
        merge_record_pair(bioschemas_record, rss_record)
      end

      merged + rss_by_url.values
    end

    def merge_record_pair(primary_record, secondary_record)
      return primary_record if secondary_record.nil?

      secondary_record.merge(primary_record) do |_key, secondary_value, primary_value|
        primary_value.present? ? primary_value : secondary_value
      end
    end
  end
end
