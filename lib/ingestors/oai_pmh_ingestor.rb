require 'tess_rdf_extractors'

module Ingestors
  class OaiPmhIngestor < Ingestor
    include DublinCoreIngestion

    def self.config
      {
        key: 'oai_pmh',
        title: 'OAI-PMH',
        user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:102.0) Gecko/20100101 Firefox/102.0',
        mail: Rails.configuration.tess['contact_email']
      }
    end

    def initialize
      super

      # to use some helper functions that are instance level methods of BioschemasIngestor
      @bioschemas_manager = BioschemasIngestor.new
    end

    def read(source_url)
      client = OAI::Client.new source_url, headers: { 'From' => config[:mail], 'User-Agent' => config[:user_agent] }
      found_bioschemas = begin
        read_oai_rdf(client)
      rescue OAI::ArgumentException
        false
      end

      read_oai_dublin_core(client) unless found_bioschemas
    end

    def ns
      {
        'dc' => 'http://purl.org/dc/elements/1.1/',
        'oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/'
      }
    end

    def extract_dublin_core_from_xml(xml_doc)
      {
        title: xml_doc.at_xpath('//dc:title', ns)&.text,
        description: xml_doc.at_xpath('//dc:description', ns)&.text,
        creators: xml_doc.xpath('//dc:creator', ns).map(&:text),
        contributors: xml_doc.xpath('//dc:contributor', ns).map(&:text),
        rights: xml_doc.xpath('//dc:rights', ns).map(&:text),
        dates: xml_doc.xpath('//dc:date', ns).map(&:text),
        identifiers: xml_doc.xpath('//dc:identifier', ns).map(&:text),
        subjects: xml_doc.xpath('//dc:subject', ns).map(&:text),
        types: xml_doc.xpath('//dc:type', ns).map(&:text),
        publisher: xml_doc.at_xpath('//dc:publisher', ns)&.text
      }
    end

    def read_oai_dublin_core(client)
      count = 0
      client.list_records(metadata_prefix: 'oai_dc').full.each do |record|
        xml_string = record.metadata.to_s
        doc = Nokogiri::XML(xml_string)
        dc = extract_dublin_core_from_xml(doc)

        types = normalize_dublin_core_values(dc[:types])
        # this event detection heuristic captures in particular
        # - http://purl.org/dc/dcmitype/Event (the standard way of typing an event in dublin core)
        # - https://schema.org/Event
        if types.any? { |t| t.downcase.include? 'event' }
          add_event(build_event_from_dublin_core_data(dc))
        else
          add_material(build_material_from_dublin_core_data(dc))
        end

        count += 1
      end
      @messages << "found #{count} records"
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

      @bioschemas_manager.deduplicate(provider_events).each do |event_params|
        add_event(event_params)
      end

      @bioschemas_manager.deduplicate(provider_materials).each do |material_params|
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
          @bioschemas_manager.convert_params(p)
        end
        courses = Tess::Rdf::CourseExtractor.new(content, :rdfxml).extract do |p|
          @bioschemas_manager.convert_params(p)
        end
        course_instances = Tess::Rdf::CourseInstanceExtractor.new(content, :rdfxml).extract do |p|
          @bioschemas_manager.convert_params(p)
        end
        learning_resources = Tess::Rdf::LearningResourceExtractor.new(content, :rdfxml).extract do |p|
          @bioschemas_manager.convert_params(p)
        end
        output[:totals]['Events'] += events.count
        output[:totals]['Courses'] += courses.count
        output[:totals]['CourseInstances'] += course_instances.count
        output[:totals]['LearningResources'] += learning_resources.count

        @bioschemas_manager.deduplicate(events + courses + course_instances).each do |event|
          output[:resources][:events] << event
        end

        @bioschemas_manager.deduplicate(learning_resources).each do |material|
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
  end
end
