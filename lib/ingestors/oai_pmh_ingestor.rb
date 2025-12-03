require 'open-uri'
require 'tess_rdf_extractors'
require 'oai'
require 'nokogiri'

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

    def ns
      {
        'dc' => 'http://purl.org/dc/elements/1.1/',
        'oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/'
      }
    end

    def read(source_url)
      client = OAI::Client.new source_url, headers: { 'From' => config[:mail] }
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
      material.licence      = xml_doc.at_xpath('//dc:rights', ns)&.text

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
  end
end
