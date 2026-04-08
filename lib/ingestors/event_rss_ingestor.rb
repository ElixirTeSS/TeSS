require 'rss'
require 'tess_rdf_extractors'

module Ingestors
  class EventRSSIngestor < Ingestor
    include RSSIngestion

    def initialize
      super

      @bioschemas_manager = BioschemasIngestor.new
    end

    def self.config
      {
        key: 'event_rss',
        title: 'RSS / Atom Feed',
        category: :events
      }
    end

    def read(url)
      feed, content = fetch_feed(url)
      return if feed.nil?

      if feed.is_a?(RSS::Rss)
        @messages << "Parsing RSS feed: #{feed_title(feed)}"
        feed.items.each { |item| add_event(build_event_from_rss_item(item)) }
      elsif feed.is_a?(RSS::RDF)
        @messages << "Parsing RSS-RDF feed: #{feed_title(feed)}"
        rss_events = feed.items.map { |item| build_event_from_rss_item(item).to_h }
        bioschemas_events = extract_rdf_bioschemas_events(content)
        merge_with_bioschemas_priority(bioschemas_events, rss_events).each do |event|
          add_event(event)
        end
      elsif feed.is_a?(RSS::Atom::Feed)
        @messages << "Parsing ATOM feed: #{feed_title(feed)}"
        feed.items.each { |item| add_event(build_event_from_atom_item(item)) }
      else
        @messages << "Parsing UNKNOWN feed: #{feed_title(feed)}"
        @messages << 'unsupported feed format'
      end
    end

    private

    def extract_rdf_bioschemas_events(content)
      return [] unless content.present?

      events = Tess::Rdf::EventExtractor.new(content, :rdfxml).extract do |params|
        @bioschemas_manager.convert_params(params)
      end
      courses = Tess::Rdf::CourseExtractor.new(content, :rdfxml).extract do |params|
        @bioschemas_manager.convert_params(params)
      end
      course_instances = Tess::Rdf::CourseInstanceExtractor.new(content, :rdfxml).extract do |params|
        @bioschemas_manager.convert_params(params)
      end

      @bioschemas_manager.deduplicate(events + courses + course_instances)
    rescue StandardError => e
      Rails.logger.error("#{e.class}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n")) if e.backtrace&.any?
      @messages << 'An error occurred while extracting Bioschemas Events.'
      []
    end

    def build_event_from_rss_item(item)
      event = build_event_from_dublin_core_data(extract_dublin_core(item))

      event.title ||= text_value(item.title)
      native_url = text_value(item.link)
      event.url = native_url if native_url.present?
      event.description ||= convert_description(text_value(item.description) || text_value(item.content_encoded))
      event.keywords = merge_unique(event.keywords, extract_rss_keywords(item))
      organizer = text_value(item.respond_to?(:author) ? item.author : nil)
      event.organizer ||= organizer
      event.contact ||= organizer

      item_date = parse_time(item.respond_to?(:pubDate) ? item.pubDate : nil) || parse_time(item.respond_to?(:date) ? item.date : nil)
      event.start = prefer_precise_time(event.start, item_date)
      event.end = prefer_precise_time(event.end, item_date)

      event
    end

    def build_event_from_atom_item(item)
      event = build_event_from_dublin_core_data(extract_dublin_core(item))

      event.title ||= text_value(item.title)
      native_url = extract_atom_link(item)
      event.url = native_url if native_url.present?
      event.description ||= convert_description(text_value(item.summary) || text_value(item.content))
      event.keywords = merge_unique(event.keywords, extract_atom_keywords(item))
      organizer = extract_atom_authors(item).first
      event.organizer ||= organizer
      event.contact ||= organizer

      published = parse_time(item.respond_to?(:published) ? item.published : nil)
      updated = parse_time(item.respond_to?(:updated) ? item.updated : nil)
      event.start = prefer_precise_time(event.start, published || updated)
      event.end = prefer_precise_time(event.end, updated || published)

      event
    end
  end
end
