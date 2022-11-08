module SourcesHelper
  SOURCES_INFO = "#{TeSS::Config.site['title_short']} provides a facility" +
    " to ingest events and materials using automated sources.".freeze

  def grouped_ingestor_options_for_select
    opts = []

    Ingestors::IngestorFactory.grouped_options.each do |category, configs|
      opts << [t("ingestion.categories.#{category}"), configs.map { |c| [c[:title], c[:key], ''] }]
    end

    opts
  end
end
