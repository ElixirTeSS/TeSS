require 'tess_rdf_extractors'

module Ingestors
  class BioschemasIngestor < Ingestor
    include Ingestors::Concerns::SitemapHelpers

    DUMMY_URL = 'https://example.com'

    attr_reader :verbose

    def self.config
      {
        key: 'bioschemas',
        title: 'Bioschemas',
        user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0'
      }
    end

    def read(source_url)
      @verbose = false
      sources = parse_sitemap(source_url)

      provider_events = []
      provider_materials = []
      totals = Hash.new(0)
      no_bioschema_urls = []
      sources.each do |url|
        source = open_url(url)
        output = read_content(source, url: url)
        if output
          provider_events += output[:resources][:events]
          provider_materials += output[:resources][:materials]
          output[:totals].each do |key, value|
            totals[key] += value
          end
          no_bioschema_urls << url if !source.nil? && output[:totals].values.sum.zero?
        end
      end

      if totals.keys.any?
        bioschemas_summary = ["Bioschemas summary:\n"]
        totals.each do |type, count|
          bioschemas_summary << " - #{type}: #{count}"
        end
        @messages << bioschemas_summary.join("\n")
      end

      @messages << "Bioschemas not found in:\n\n#{no_bioschema_urls.map { |u| " - #{u}" }.join("\n")}" if no_bioschema_urls.any?

      deduplicate(provider_events).each do |event_params|
        add_event(event_params)
      end

      deduplicate(provider_materials).each do |material_params|
        add_material(material_params)
      end
    end

    def read_content(content, url: nil)
      output = {
        resources: {
          events: [],
          materials: []
        },
        totals: Hash.new(0)
      }

      return output unless content

      begin
        sample = content.read(256)&.strip
        return output unless sample

        format = sample.start_with?('[') || sample.start_with?('{') ? :jsonld : :rdfa
        content.rewind
        output = extract_resources(content.read, format: format, url: url)
      rescue StandardError => e
        Rails.logger.error("#{e.class}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n")) if e.backtrace&.any?
        error = 'An error'
        comment = nil
        if e.is_a?(RDF::ReaderError)
          error = 'A parsing error'
          comment = 'Please check your page contains valid JSON-LD or HTML.'
        end
        message = String.new("#{error} occurred while reading")
        if url.present? && url != 'https://example.com'
          message << ": #{url} "
        else
          message << " the source"
        end
        message << ". #{comment}" if comment
        @messages << message
      end

      output
    end

    def extract_resources(content, format:, url: nil, types: %i[events materials])
      output = { resources: { events: [], materials: [] }, totals: Hash.new(0) }
      return output unless content

      extractors = {
        events: {
          'Events' => Tess::Rdf::EventExtractor,
          'Courses' => Tess::Rdf::CourseExtractor,
          'CourseInstances' => Tess::Rdf::CourseInstanceExtractor
        },
        materials: { 'LearningResources' => Tess::Rdf::LearningResourceExtractor }
      }
      types.each do |type|
        extractors.fetch(type).each do |name, extractor|
          records = extractor.new(content, format, base_uri: url).extract { |params| convert_params(params) }
          output[:totals][name] = records.count
          output[:resources][type].concat(records)
          puts "#{name}: #{records.count}" if verbose
        end
        output[:resources][type] = deduplicate(output[:resources][type])
      end
      output
    end

    # If duplicate resources have been extracted, prefer ones with the most metadata.
    def deduplicate(resources)
      return [] unless resources.any?

      puts "De-duplicating #{resources.count} resources" if verbose
      hash = {}
      scores = {}
      resources.each do |resource|
        resource_url = resource[:url]
        puts "  Considering: #{resource_url}" if verbose
        if hash[resource_url]
          score = metadata_score(resource)
          # Replace the resource if this resource has a higher metadata score
          puts "    Duplicate! Comparing #{score} vs. #{scores[resource_url]}" if verbose
          if score > scores[resource_url]
            puts '    Replacing resource' if verbose
            hash[resource_url] = resource
            scores[resource_url] = score
          end
        else
          puts '    Not present, adding' if verbose
          hash[resource_url] = resource
          scores[resource_url] = metadata_score(resource)
        end
      end

      puts "#{hash.values.count} resources after de-duplication" if verbose

      hash.values
    end

    # Score based on number of metadata fields available
    def metadata_score(resource)
      score = 0
      resource.each_value do |value|
        score += 1 unless value.nil? || value == {} || value == [] || (value.is_a?(String) && value.strip == '')
      end

      score
    end

    def convert_params(params)
      params[:description] = convert_description(params[:description]) if params.key?(:description)

      params
    end
  end
end
