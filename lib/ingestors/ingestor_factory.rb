module Ingestors
  class IngestorFactory
    def self.ingestors
      [
        Ingestors::EventCsvIngestor,
        Ingestors::MaterialCsvIngestor,
        Ingestors::IcalIngestor,
        Ingestors::EventbriteIngestor,
        Ingestors::TessEventIngestor,
        Ingestors::ZenodoIngestor
      ]
    end

    def self.ingestor_config
      @ingestor_config ||= ingestors.map do |i|
        i.config.merge(ingestor: i)
      end
    end

    def self.get_ingestor(method)
      config = fetch_ingestor_config(method)
      if config
        return config[:ingestor].new
      else
        raise "Invalid method: [#{method}]"
      end
    end

    def self.fetch_ingestor_config(key)
      ingestor_config.detect { |c| c[:key] == key }
    end

    def self.grouped_options
      @grouped_options ||= ingestor_config.group_by { |c| c[:category] || :any }
    end

    def self.get_method_value(input)
      METHODS.fetch input.to_sym
    end
  end
end
