module Ingestors
  class IngestorFactory
    def self.ingestors
      [
        Ingestors::BioschemasIngestor,
        Ingestors::DansIngestor,
        Ingestors::DtlsIngestor,
        Ingestors::EventbriteIngestor,
        Ingestors::EventCsvIngestor,
        Ingestors::IcalIngestor,
        Ingestors::LeidenIngestor,
        Ingestors::LibcalIngestor,
        Ingestors::MaastrichtIngestor,
        Ingestors::MaterialCsvIngestor,
        Ingestors::NwoIngestor,
        Ingestors::OscmIngestor,
        Ingestors::SurfIngestor,
        Ingestors::TessEventIngestor,
        Ingestors::UtwenteIngestor,
        Ingestors::UuIngestor,
        Ingestors::UvaIngestor,
        Ingestors::WurIngestor,
        Ingestors::ZenodoIngestor,
        Ingestors::RugIngestor,
        Ingestors::LcrdmIngestor,
        Ingestors::TdccIngestor,
        Ingestors::UhasseltIngestor,
        Ingestors::OdisseiIngestor,
        Ingestors::RstIngestor,
        Ingestors::OsciIngestor,
        Ingestors::DccIngestor,
        Ingestors::SenseIngestor,
        Ingestors::LlmIngestor
      ]
    end

    def self.ingestor_config
      @ingestor_config ||= ingestors.map do |i|
        [i.config[:key], i.config.merge(ingestor: i)]
      end.to_h
    end

    def self.get_ingestor(method)
      config = ingestor_config[method]
      raise "Invalid method: [#{method}]" unless config

      config[:ingestor].new
    end

    def self.valid_ingestor?(method)
      ingestor_config.key?(method)
    end

    def self.grouped_options
      @grouped_options ||= ingestor_config.values.group_by { |c| c[:category] || :any }
    end

    def self.get_method_value(input)
      METHODS.fetch input.to_sym
    end
  end
end
