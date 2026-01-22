require 'open-uri'
require 'tess_rdf_extractors'

module Ingestors
  class OaiPmhIngestor < Ingestor
    DUMMY_URL = 'https://example.com'

    attr_reader :verbose

    def self.config
      {
        key: 'oai_pmh',
        title: 'OAI-PMH',
        user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0',
        mail: Rails.configuration.tess['contact_email']
      }
    end

    def read(source_url)
      client = OAI::Client.new source_url, headers: { 'From' => config[:mail] }
      found_bioschemas = begin
        read_oai_rdf(client)
      rescue OAI::ArgumentException
        false
      end

      read_oai_default(client) unless found_bioschemas
    end

    def ns
      {
        'dc' => 'http://purl.org/dc/elements/1.1/',
        'oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/'
      }
    end

    def read_oai_default(client)
      count = 0
      client.list_records.full.each do |record|
        read_dublin_core(record.metadata.to_s)
        count += 1
      end
      @messages << "found #{count} records"
    end

    def read_dublin_core(xml_string)
      doc = Nokogiri::XML(xml_string)

      types = doc.xpath('//dc:type', ns).map(&:text)
      if types.include?('http://purl.org/dc/dcmitype/Event')
        read_dublin_core_event(doc)
      else
        read_dublin_core_material(doc)
      end
    end

    def read_dublin_core_material(xml_doc)
      material = OpenStruct.new
      material.title        = xml_doc.at_xpath('//dc:title', ns)&.text
      material.description  = convert_description(xml_doc.at_xpath('//dc:description', ns)&.text)
      material.authors      = xml_doc.xpath('//dc:creator', ns).map(&:text)
      material.contributors = xml_doc.xpath('//dc:contributor', ns).map(&:text)

      rights = xml_doc.xpath('//dc:rights', ns).map { |n| n.text&.strip }.reject(&:empty?)
      material.licence = rights.find { |r| r.start_with?('http://', 'https://') } || rights.first || 'notspecified'

      dates = xml_doc.xpath('//dc:date', ns).map(&:text)
      parsed_dates = dates.map do |d|
        Date.parse(d)
      rescue StandardError
        nil
      end.compact
      material.date_created = parsed_dates.first
      material.date_modified = parsed_dates.last if parsed_dates.size > 1

      identifiers = xml_doc.xpath('//dc:identifier', ns).map(&:text)
      doi = identifiers.find { |id| id.start_with?('10.') || id.include?('doi.org') }
      if doi
        doi = doi&.sub(%r{https?://doi\.org/}, '')
        material.doi = "https://doi.org/#{doi}"
      end
      material.url = identifiers.find { |id| id.start_with?('http://', 'https://') }

      material.keywords = xml_doc.xpath('//dc:subject', ns).map(&:text)
      material.resource_type = xml_doc.xpath('//dc:type', ns).map(&:text)
      material.contact = xml_doc.at_xpath('//dc:publisher', ns)&.text

      add_material material
    end

    def read_dublin_core_event(_xml_doc)
      event = OpenStruct.new

      event.title       = doc.at_xpath('//dc:title', ns)&.text
      event.description = convert_description(doc.at_xpath('//dc:description', ns)&.text)
      event.url         = doc.xpath('//dc:identifier', ns).map(&:text).find { |id| id.start_with?('http://', 'https://') }
      event.contact     = doc.at_xpath('//dc:publisher', ns)&.text
      event.organizer   = doc.at_xpath('//dc:creator', ns)&.text
      event.keywords = doc.xpath('//dc:subject', ns).map(&:text)
      event.event_types = types

      dates = doc.xpath('//dc:date', ns).map(&:text)
      parsed_dates = dates.map do |d|
        Date.parse(d)
      rescue StandardError
        nil
      end.compact
      event.start = parsed_dates.first
      event.end   = parsed_dates.last

      add_event event
    end

    def read_oai_rdf(client)
      provider_events = []
      provider_materials = []
      totals = Hash.new(0)

      client.list_records(metadata_prefix: 'rdf').full.each do |record|
        metadata_tag = Nokogiri::XML(record.metadata.to_s)
        bioschemas_xml = metadata_tag.at_xpath('metadata/rdf:RDF', 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#')&.to_s
        output = parse_bioschemas(bioschemas_xml)
        next unless output

        provider_events += output[:resources][:events]
        provider_materials += output[:resources][:materials]
        output[:totals].each do |key, value|
          totals[key] += value
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

      provider_events.any? || provider_materials.any?
    end

    def parse_bioschemas(content)
      output = {
        resources: {
          events: [],
          materials: []
        },
        totals: Hash.new(0)
      }

      return output unless content

      begin
        events = Tess::Rdf::EventExtractor.new(content, :rdfxml).extract do |p|
          convert_params(p)
        end
        courses = Tess::Rdf::CourseExtractor.new(content, :rdfxml).extract do |p|
          convert_params(p)
        end
        course_instances = Tess::Rdf::CourseInstanceExtractor.new(content, :rdfxml).extract do |p|
          convert_params(p)
        end
        learning_resources = Tess::Rdf::LearningResourceExtractor.new(content, :rdfxml).extract do |p|
          convert_params(p)
        end
        output[:totals]['Events'] += events.count
        output[:totals]['Courses'] += courses.count
        output[:totals]['CourseInstances'] += course_instances.count
        output[:totals]['LearningResources'] += learning_resources.count

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
          comment = 'Please check your page contains valid RDF/XML.'
        end
        message = "#{error} occurred while reading the source."
        message << " #{comment}" if comment
        @messages << message
      end

      output
    end

    # ---- This is copied unchanged from bioschemas_ingestor.rb and needs to be refactored. ----

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
