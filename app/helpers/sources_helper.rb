require 'ingestors/ingestor_factory'

module SourcesHelper
  SOURCES_INFO = "#{TeSS::Config.site['title_short']} provides a facility" +
    " to ingest events and materials using automated sources.".freeze

  # Returns an array of two-element arrays of licences ready to be used in options_for_select()
  # for generating option/select tags
  def source_methods_options_for_select
    IngestorFactory.method_for_select
  end

  def source_resources_options_for_select
    IngestorFactory.resources_for_select
  end

  def get_source_title source
    result = source.content_provider.title + ": " +
      IngestorFactory.get_method_value(source.method)
  end

end
