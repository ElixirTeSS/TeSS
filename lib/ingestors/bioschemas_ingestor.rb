require 'open-uri'
require 'tess_rdf_extractors'

module Ingestors
  class BioschemasIngestor < Ingestor
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
      sitemap_regex = nil
      @verbose = false
      sources = if source_url.downcase.match?(/sitemap(.*)?.xml\Z/)
                  sitemap_message = "Parsing sitemap: #{source_url}\n"
                  urls = SitemapParser.new(source_url, {
                    recurse: true,
                    url_regex: sitemap_regex,
                    headers: { 'User-Agent' => config[:user_agent] }
                  }).to_a.uniq.map(&:strip)
                  sitemap_message << "\n - #{urls.count} URLs found"
                  @messages << sitemap_message
                  urls
                else
                  [source_url]
                end

      provider_events = []
      provider_materials = []
      totals = Hash.new(0)
      sources.each do |url|
        source = open_url(url)
        output = read_content(source, url: url)
        if output
          provider_events += output[:resources][:events]
          provider_materials += output[:resources][:materials]
          output[:totals].each do |key, value|
            totals[key] += value
          end
        end
      end

      if totals.keys.any?
        bioschemas_summary = "Bioschemas summary:\n"
        totals.each do |type, count|
          bioschemas_summary << "\n - #{type}: #{count}"
        end
        @messages << bioschemas_summary
      end

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
        source = content.read
        events = Tess::Rdf::EventExtractor.new(source, format, base_uri: url).extract do |p|
          convert_params(p)
        end
        courses = Tess::Rdf::CourseExtractor.new(source, format, base_uri: url).extract do |p|
          convert_params(p)
        end
        course_instances = Tess::Rdf::CourseInstanceExtractor.new(source, format, base_uri: url).extract do |p|
          convert_params(p)
        end
        learning_resources = Tess::Rdf::LearningResourceExtractor.new(source, format, base_uri: url).extract do |p|
          convert_params(p)
        end
        output[:totals]['Events'] += events.count
        output[:totals]['Courses'] += courses.count
        output[:totals]['CourseInstances'] += course_instances.count
        output[:totals]['LearningResources'] += learning_resources.count
        if verbose
          puts "Events: #{events.count}"
          puts "Courses: #{courses.count}"
          puts "CourseInstances: #{course_instances.count}"
          puts "LearningResources: #{learning_resources.count}"
        end

        deduplicate(events + courses + course_instances).each do |event|
          output[:resources][:events] << event
        end

        deduplicate(learning_resources).each do |material|
          output[:resources][:materials] << material
        end
      rescue StandardError => e
        Rails.logger.error("#{e.class}: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n")) if e.backtrace&.any?
        error = 'An error'
        comment = nil
        if e.is_a?(RDF::ReaderError)
          error = 'A parsing error'
          comment = 'Please check your page contains valid JSON-LD or HTML.'
        end
        message = "#{error} occurred while reading"
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
