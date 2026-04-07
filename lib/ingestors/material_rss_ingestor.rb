require 'rss'
require 'tess_rdf_extractors'

module Ingestors
  class MaterialRssIngestor < Ingestor
    include RssIngestion

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
      feed, content = fetch_feed(url)
      return if feed.nil?

      if feed.is_a?(RSS::Rss)
        @messages << "Parsing RSS feed: #{feed_title(feed)}"
        feed.items.each { |item| add_material(build_material_from_rss_item(item)) }
      elsif feed.is_a?(RSS::RDF)
        @messages << "Parsing RSS-RDF feed: #{feed_title(feed)}"
        rss_materials = feed.items.map { |item| build_material_from_rss_item(item).to_h }
        bioschemas_materials = extract_rdf_bioschemas_materials(content)
        merge_with_bioschemas_priority(bioschemas_materials, rss_materials).each do |material|
          add_material(material)
        end
      elsif feed.is_a?(RSS::Atom::Feed)
        @messages << "Parsing ATOM feed: #{feed_title(feed)}"
        feed.items.each { |item| add_material(build_material_from_atom_item(item)) }
      else
        @messages << "Parsing UNKNOWN feed: #{feed_title(feed)}"
        @messages << 'unsupported feed format'
      end
    end

    private

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

    def build_material_from_rss_item(item)
      material = build_material_from_dublin_core_data(extract_dublin_core(item))

      material.title ||= text_value(item.title)
      native_url = text_value(item.link)
      material.url = native_url if native_url.present?
      material.description ||= convert_description(text_value(item.description) || text_value(item.content_encoded))
      material.keywords = merge_unique(material.keywords, extract_rss_keywords(item))
      author = item.respond_to?(:author) ? item.author : nil
      material.authors = merge_unique(material.authors, [text_value(author)])
      material.contact ||= material.authors&.first
      guid = item.respond_to?(:guid) ? item.guid : nil
      material.doi ||= extract_dublin_core_doi([text_value(guid)])

      item_date = parse_time(item.respond_to?(:pubDate) ? item.pubDate : nil) || parse_time(item.respond_to?(:date) ? item.date : nil)
      material.date_published ||= item_date
      material.date_created = prefer_precise_time(material.date_created, item_date)
      material.date_modified = prefer_precise_time(material.date_modified, parse_time(item.respond_to?(:date) ? item.date : nil))

      material
    end

    def build_material_from_atom_item(item)
      material = build_material_from_dublin_core_data(extract_dublin_core(item))

      material.title ||= text_value(item.title)
      native_url = extract_atom_link(item)
      material.url = native_url if native_url.present?
      material.description ||= convert_description(text_value(item.summary) || text_value(item.content))
      material.keywords = merge_unique(material.keywords, extract_atom_keywords(item))
      material.authors = merge_unique(material.authors, extract_atom_authors(item))
      material.contact ||= material.authors&.first
      material.doi ||= extract_dublin_core_doi([text_value(item.id)])

      published = parse_time(item.respond_to?(:published) ? item.published : nil)
      updated = parse_time(item.respond_to?(:updated) ? item.updated : nil)
      material.date_created = prefer_precise_time(material.date_created, published)
      material.date_published ||= published || updated
      material.date_modified = prefer_precise_time(material.date_modified, updated)

      material
    end
  end
end
