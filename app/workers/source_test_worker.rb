# frozen_string_literal: true

require 'tess_rdf_extractors'
require 'open-uri'

class SourceTestWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker # Note Sidekiq::Status here, so we can monitor job status
  sidekiq_options retry: 2, queue: :source_testing

  def perform(source_id)
    source = Source.find_by(id: source_id)
    return unless source

    results = {
      events: [],
      materials: [],
      messages: []
    }
    start_time = Time.zone.now
    exception = nil
    begin
      ingestor = Ingestors::IngestorFactory.get_ingestor(source.method)
      ingestor.token = source.token
      ingestor.read(source.url)
      results = {
        events: ingestor.events.map(&:to_h),
        materials: ingestor.materials.map(&:to_h),
        messages: ingestor.messages
      }
    rescue StandardError => e
      results[:messages] << 'Ingestor encountered an unexpected error'
      exception = e
    end

    results[:run_time] = Time.zone.now - start_time
    results[:finished_at] = Time.zone.now
    source.test_results = results

    raise exception if exception
  end
end
