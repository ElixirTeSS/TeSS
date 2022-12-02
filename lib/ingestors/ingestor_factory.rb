module Ingestors
  class IngestorFactory
    def self.ingestors
      [
        Ingestors::EventCsvIngestor,
        Ingestors::MaterialCsvIngestor,
        Ingestors::IcalIngestor,
        Ingestors::EventbriteIngestor,
        Ingestors::TessEventIngestor,
        Ingestors::ZenodoIngestor,
        Ingestors::BioschemasIngestor
      ]
    end

    def self.ingestor_config
      @ingestor_config ||= ingestors.map do |i|
        [i.config[:key], i.config.merge(ingestor: i)]
      end.to_h
    end

    def self.get_ingestor(method)
      config = ingestor_config[method]
      if config
        config[:ingestor].new
      else
        raise "Invalid method: [#{method}]"
      end
    end

    def self.grouped_options
      @grouped_options ||= ingestor_config.values.group_by { |c| c[:category] || :any }
    end

    def self.get_method_value(input)
      METHODS.fetch input.to_sym
    end
  end
end
