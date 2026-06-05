module Ingestors
  module RSSIngestion
    include DublinCoreIngestion

    # Core functionality that runs and manages RSS ingestion

    def read_from_rss_feed(url)
      parsed_feed_data = fetch_and_parse_feed(url)
      return if parsed_feed_data.blank?

      feed = parsed_feed_data[:feed]
      content = parsed_feed_data[:content]
      feed_url = parsed_feed_data[:feed_url]

      case feed
      when RSS::Rss
        @messages << 'Parsing RSS feed'
        feed.items.each do |item|
          ingest_record(build_record_from_rss_item(item, feed_url))
        end
      when RSS::RDF
        @messages << 'Parsing RSS-RDF feed'
        rss_records = feed.items.map { |item| build_record_from_rss_item(item, feed_url).to_h }
        bioschemas_records = extract_rdf_bioschemas_records(content)
        merge_rss_and_bioschemas_records(rss_records, bioschemas_records).each do |record|
          ingest_record(record)
        end
      when RSS::Atom::Feed
        @messages << 'Parsing ATOM feed'
        feed.items.each do |item|
          ingest_record(build_record_from_atom_item(item, feed_url))
        end
      else
        @messages << "unsupported feed format: #{feed.class}"
      end
    end

    def fetch_and_parse_feed(url, discover_on_failure: true)
      io = open_url(url)
      return if io.nil?

      content = io.read
      parse_error = nil
      feed = begin
        RSS::Parser.parse(content, { validate: false, ignore_unknown_element: true })
      rescue RSS::Error => e
        parse_error = e
        nil
      end

      error_message = if parse_error
                        "parsing feed failed with #{parse_error.class}: #{parse_error.message}"
                      else
                        'parsing feed failed with: unrecognized feed content'
                      end

      if feed.blank? && discover_on_failure
        discovered_url = discover_feed_url(content, url)
        if discovered_url.blank?
          @messages << error_message
          @messages << "Attempted HTML feed discovery, but no RSS/Atom alternate feed link was found in: #{url}"
          return
        end

        return fetch_and_parse_feed(discovered_url, discover_on_failure: false)
      end

      if feed.blank?
        @messages << error_message
        return
      end

      {
        feed:,
        content:,
        feed_url: url
      }
    end

    def discover_feed_url(content, base_url)
      doc = Nokogiri::HTML(content)
      link = doc.css('link[rel]').find do |node|
        rel = node['rel'].to_s.downcase
        type = node['type'].to_s.downcase
        rel.include?('alternate') && (type.include?('rss') || type.include?('atom'))
      end

      href = link&.[]('href')
      url = Addressable::URI.join(base_url, href).to_s if href.present?
      return nil unless url.present?

      @messages << "Found RSS/Atom feed link in HTML page, following: #{url}"
      url
    end

    def merge_rss_and_bioschemas_records(rss_records, bioschemas_records)
      # Merges based on URL. Prefers bioschemas values on conflict.
      rss_by_url = rss_records.index_by { |record| record[:url].to_s }
      merged_records = bioschemas_records.map do |bioschemas_record|
        key = bioschemas_record[:url].to_s
        rss_record = rss_by_url.delete(key)

        if rss_record.nil?
          bioschemas_record
        else
          rss_record.merge(bioschemas_record) do |_key, rss_value, bioschemas_value|
            bioschemas_value.present? ? bioschemas_value : rss_value
          end
        end
      end

      merged_records + rss_by_url.values
    end

    # Hook methods

    def ingest_record(_record)
      # call add_event or add_material
      raise NotImplementedError
    end

    def build_record_from_rss_item(_item, _feed_url)
      raise NotImplementedError
    end

    def build_record_from_atom_item(_item, _feed_url)
      raise NotImplementedError
    end

    def extract_rdf_bioschemas_records(_content)
      raise NotImplementedError
    end

    # Helper methods that are used by hook implementations

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
      links = Array(item.links)

      preferred_link = links.find do |link|
        href = text_value(link.href)
        rel = text_value(link.respond_to?(:rel) ? link.rel : nil).to_s.downcase

        href.present? && (rel.blank? || rel == 'alternate')
      end
      return text_value(preferred_link.href) if preferred_link.present?

      links.map { |link| text_value(link.href) }.find(&:present?)
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
  end
end
