require 'tess_rdf_extractors'
require 'open-uri'

class SourceTestWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker # Note Sidekiq::Status here, so we can monitor job status
  sidekiq_options retry: 2, queue: :source_testing

  def perform(source_id)
    source = Source.find_by_id(source_id)
    return unless source

    results = {
      events: [],
      materials: [],
      content_providers: [],
      messages: []
    }
    start_time = Time.now
    exception = nil
    begin
      ingestor = Ingestors::IngestorFactory.get_ingestor(source)
      ingestor.read(source.url)
      ingestor.filter
      ingestor.resolve_providers
      results = {
        events: ingestor.events,
        materials: ingestor.materials,
        content_providers: ingestor.providers,
        messages: ingestor.messages
      }
    rescue StandardError => e
      results[:messages] << 'Ingestor encountered an unexpected error'
      exception = e
    end

    results[:run_time] = Time.now - start_time
    results[:finished_at] = Time.now
    source.test_results = results

    raise exception if exception
  end
end
