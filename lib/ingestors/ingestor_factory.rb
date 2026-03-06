module Ingestors
  class IngestorFactory
    def self.ingestors
      [
        Ingestors::BioschemasIngestor,
        Ingestors::EventbriteIngestor,
        Ingestors::EventCsvIngestor,
        Ingestors::IcalIngestor,
        Ingestors::IndicoIngestor,
        Ingestors::LibcalIngestor,
        Ingestors::MaterialCsvIngestor,
        Ingestors::TessEventIngestor,
        Ingestors::ZenodoIngestor,
        Ingestors::OaiPmhIngestor,
        Ingestors::GithubIngestor,
      ] + taxila_ingestors + llm_ingestors
    end

    def self.taxila_ingestors
      [
        Ingestors::Taxila::DansIngestor,
        Ingestors::Taxila::DtlsIngestor,
        Ingestors::Taxila::LeidenIngestor,
        Ingestors::Taxila::MaastrichtIngestor,
        Ingestors::Taxila::NwoIngestor,
        Ingestors::Taxila::OscmIngestor,
        Ingestors::Taxila::SurfIngestor,
        Ingestors::Taxila::UtwenteIngestor,
        Ingestors::Taxila::UuIngestor,
        Ingestors::Taxila::UvaIngestor,
        Ingestors::Taxila::WurIngestor,
        Ingestors::Taxila::RugIngestor,
        Ingestors::Taxila::LcrdmIngestor,
        Ingestors::Taxila::TdccIngestor,
        Ingestors::Taxila::UhasseltIngestor,
        Ingestors::Taxila::OdisseiIngestor,
        Ingestors::Taxila::RstIngestor,
        Ingestors::Taxila::OsciIngestor,
        Ingestors::Taxila::DccIngestor,
        Ingestors::Taxila::SenseIngestor,
        Ingestors::Taxila::VuMaterialIngestor,
        Ingestors::Taxila::RdnlIngestor,
        Ingestors::Taxila::HanIngestor,
        Ingestors::Taxila::CitizenScienceIngestor
      ]
    end

    def self.llm_ingestors
      [
        Ingestors::Taxila::FourtuLlmIngestor
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
