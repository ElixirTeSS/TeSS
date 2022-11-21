require 'tess_rdf_extractors'
require 'open-uri'

class SourceTestWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker # Note Sidekiq::Status here, so we can monitor job status
  sidekiq_options retry: 2

  def perform(source_id)
    source = Source.find_by_id(source_id)
    return unless source
    ingestor = Ingestors::IngestorFactory.get_ingestor(source.method)
    ingestor.token = source.token

    start_time = Time.now
    exception = nil
    begin
      ingestor.read(source.url)
    rescue StandardError => e
      ingestor.messages << "Ingestor encountered an unexpected error"
      exception = e
    end
    source.test_results = {
      # This is a mega hack because serializing resources as YAML is a pain
      events: ingestor.events.map { |r| r.attributes },
      materials: ingestor.materials.map { |r| r.attributes },
      messages: ingestor.messages,
      run_time: Time.now - start_time,
      finished_at: Time.now
    }

    raise exception if exception
  end
end
