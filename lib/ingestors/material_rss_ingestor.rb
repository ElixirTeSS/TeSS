require 'tess_rdf_extractors'

module Ingestors
  class MaterialRSSIngestor < Ingestor
    include DublinCoreIngestion

    def initialize
      super

      @bioschemas_manager = BioschemasIngestor.new
    end

    def self.config
      {
        key: 'material_rss',
        title: 'RSS / Atom Feed',
        category: :materials
      }
    end

    def read(url)
      io = open_url(url)
      return if io.nil?

      source_url = url
      content = io.read
      feed, parse_error_message = parse_feed(content)

      unless feed
        discovered_feed_url = discover_feed_url(content, source_url)
        if discovered_feed_url.blank?
          @messages << parse_error_message
          @messages << 'Attempted feed discovery, but no feed URL was found.'
          return
        end

        io = open_url(discovered_feed_url)
        return if io.nil?

        content = io.read
        feed, parse_error_message = parse_feed(content)
        unless feed
          @messages << parse_error_message
          return
        end

        source_url = discovered_feed_url
      end

      if feed.is_a?(RSS::Rss)
        @messages << "Parsing RSS feed: #{feed_title(feed)}"
        feed.items.each { |item| add_material(build_material_from_rss_item(item, source_url)) }
      elsif feed.is_a?(RSS::RDF)
        @messages << "Parsing RSS-RDF feed: #{feed_title(feed)}"
        rss_materials = feed.items.map { |item| build_material_from_rss_item(item, source_url).to_h }
        bioschemas_materials = extract_rdf_bioschemas_materials(content)
        merge_with_bioschemas_priority(bioschemas_materials, rss_materials).each do |material|
          add_material(material)
        end
      elsif feed.is_a?(RSS::Atom::Feed)
        @messages << "Parsing ATOM feed: #{feed_title(feed)}"
        feed.items.each { |item| add_material(build_material_from_atom_item(item, source_url)) }
      else
        @messages << "Parsing UNKNOWN feed: #{feed_title(feed)}"
        @messages << 'unsupported feed format'
      end
    end

    private

    def parse_feed(content)
      feed = RSS::Parser.parse(content, { validate: false })
      return [feed, nil] if feed.present?

      [nil, 'parsing feed failed with: unrecognized feed content']
    rescue RSS::Error => e
      [nil, "parsing feed failed with #{e.class}: #{e.message}"]
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
      @messages << "Found RSS/Atom feed link in HTML page, following: #{url}" if url
      url
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

    def merge_with_bioschemas_priority(bioschemas_records, rss_records)
      rss_by_url = rss_records.index_by { |record| record[:url].to_s }

      merged = bioschemas_records.map do |bioschemas_record|
        key = bioschemas_record[:url].to_s
        rss_record = rss_by_url.delete(key)
        if rss_record.nil?
          bioschemas_record
        else
          rss_record.merge(bioschemas_record) do |_k, rss_value, bioschemas_value|
            bioschemas_value.present? ? bioschemas_value : rss_value
          end
        end
      end

      merged + rss_by_url.values
    end

    def extract_rdf_bioschemas_materials(content)
      return [] unless content.present?

      materials = Tess::Rdf::LearningResourceExtractor.new(content, :rdfxml).extract do |params|
        @bioschemas_manager.convert_params(params)
      end

      @bioschemas_manager.deduplicate(materials)
    rescue StandardError => e
      Rails.logger.error("#{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace&.any?
      @messages << 'An error occurred while extracting Bioschemas LearningResources.'
      []
    end

    def build_material_from_rss_item(item, feed_url)
      material = build_material_from_dublin_core_data(extract_dublin_core(item))

      material.title ||= text_value(item.title)
      material.url = Addressable::URI.join(feed_url, text_value(item.link)).to_s
      itunes_summary = text_value(item.itunes_summary) if item.respond_to?(:itunes_summary)
      material.description ||= convert_description(text_value(item.description) || text_value(item.content_encoded) || itunes_summary)
      rss_keywords = if item.respond_to?(:categories)
                       Array(item.categories).map { |c| text_value(c.respond_to?(:content) ? c.content : c) }
                     else
                       []
                     end
      material.keywords = merge_unique(material.keywords, rss_keywords)
      author = item.author if item.respond_to?(:author)
      itunes_author = item.itunes_author if item.respond_to?(:itunes_author)
      material.authors = merge_unique(material.authors, [text_value(author)] + [text_value(itunes_author)].compact)
      material.contact ||= material.authors&.first
      guid = item.guid if item.respond_to?(:guid)
      material.doi ||= extract_dublin_core_doi([text_value(guid)])

      item_date = parse_time(item.pubDate) if item.respond_to?(:pubDate)
      item_date ||= parse_time(item.date) if item.respond_to?(:date)
      material.date_published ||= item_date
      material.date_created = prefer_precise_time(material.date_created, item_date)
      material.date_modified = prefer_precise_time(material.date_modified, parse_time(item.date)) if item.respond_to?(:date)

      material
    end

    def build_material_from_atom_item(item, feed_url)
      material = build_material_from_dublin_core_data(extract_dublin_core(item))

      media_title = text_value(item.media_group&.media_title)
      material.title ||= text_value(item.title) || media_title
      material.url = Addressable::URI.join(feed_url, text_value(extract_atom_link(item))).to_s
      media_group_description = text_value(item.media_group&.media_description)
      material.description ||= convert_description(text_value(item.summary) || text_value(item.content) || media_group_description)
      atom_keywords = if item.respond_to?(:categories)
                        Array(item.categories).map { |c| text_value(c.respond_to?(:term) ? c.term : c) }
                      else
                        []
                      end
      atom_authors = Array(item.authors).map { |author| text_value(author.respond_to?(:name) ? author.name : author) }
      material.keywords = merge_unique(material.keywords, atom_keywords)
      material.authors = merge_unique(material.authors, atom_authors)
      material.contact ||= material.authors&.first
      material.doi ||= extract_dublin_core_doi([text_value(item.id)])

      published = parse_time(item.published)
      updated = parse_time(item.updated)
      material.date_created = prefer_precise_time(material.date_created, published)
      material.date_published ||= published || updated
      material.date_modified = prefer_precise_time(material.date_modified, updated)

      material
    end
  end
end
