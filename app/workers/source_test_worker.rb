require 'tess_rdf_extractors'
require 'open-uri'

class SourceTestWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker # Note Sidekiq::Status here, so we can monitor job status

  def perform(source_id)
    source = Source.find_by_id(source_id)
    return unless source
    ingestor = Ingestors::IngestorFactory.get_ingestor(source.method)
    ingestor.token = source.token

    start_time = Time.now
    ingestor.read(source.url)

    source.test_results = {
      # This is a mega hack because serializing resources as YAML is a pain
      events: ingestor.events.map { |r| JSON.parse(r.to_json) },
      materials: ingestor.materials.map { |r| JSON.parse(r.to_json) },
      messages: ingestor.messages,
      run_time: Time.now - start_time
    }
  end
end
