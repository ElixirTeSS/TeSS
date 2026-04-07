module Ingestors
  module DublinCoreIngestion
    def build_material_from_dublin_core_data(dc)
      material = OpenStruct.new

      material.title = dc[:title]
      material.description = convert_description(dc[:description])
      material.authors = normalize_dublin_core_values(dc[:creators])
      material.contributors = normalize_dublin_core_values(dc[:contributors])

      rights = normalize_dublin_core_values(dc[:rights])
      material.licence = rights.find { |r| r.start_with?('http://', 'https://') } || rights.first || 'notspecified'

      parsed_dates = parse_dublin_core_dates(dc[:dates])
      material.date_created = parsed_dates.first
      material.date_modified = parsed_dates.last if parsed_dates.size > 1

      identifiers = normalize_dublin_core_values(dc[:identifiers])
      material.doi = extract_dublin_core_doi(identifiers)
      material.url = identifiers.find { |id| id.start_with?('http://', 'https://') }

      material.keywords = normalize_dublin_core_values(dc[:subjects])
      material.resource_type = normalize_dublin_core_values(dc[:types])
      material.contact = dublin_core_text(dc[:publisher])

      material
    end

    def build_event_from_dublin_core_data(dc)
      event = OpenStruct.new

      event.title = dc[:title]
      event.description = convert_description(dc[:description])
      event.organizer = normalize_dublin_core_values(dc[:creators]).first
      event.contact = dublin_core_text(dc[:publisher]) || event.organizer
      event.keywords = normalize_dublin_core_values(dc[:subjects])
      event.event_types = normalize_dublin_core_values(dc[:types])

      dates = parse_dublin_core_dates(dc[:dates])
      event.start = dates.first
      event.end = dates.last || dates.first

      identifiers = normalize_dublin_core_values(dc[:identifiers])
      event.url = identifiers.find { |id| id.start_with?('http://', 'https://') }

      event
    end

    def parse_dublin_core_dates(dates)
      normalize_dublin_core_values(dates).map do |date_value|
        Date.parse(date_value)
      rescue StandardError
        nil
      end.compact
    end

    def extract_dublin_core_doi(identifiers)
      doi = normalize_dublin_core_values(identifiers).find do |id|
        id.start_with?('10.') || id.start_with?('https://doi.org/') || id.start_with?('http://doi.org/')
      end
      return nil unless doi

      normalized = doi.sub(%r{https?://doi\.org/}, '')
      "https://doi.org/#{normalized}"
    end

    def normalize_dublin_core_values(values)
      Array(values).map { |v| dublin_core_text(v) }
                   .map(&:to_s)
                   .map(&:strip)
                   .reject(&:blank?)
                   .uniq
    end

    # this method is also used by RSS ingestion under an alias
    def dublin_core_text(value)
      return nil if value.nil?
      return value.content if value.respond_to?(:content)
      return value.text if value.respond_to?(:text) && !value.is_a?(String)

      value.to_s
    end
  end
end
