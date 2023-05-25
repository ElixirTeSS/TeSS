# frozen_string_literal: true

require 'test_helper'
require 'sidekiq/testing'

class SourceTestWorkerTest < ActiveSupport::TestCase
  test 'test source' do
    mock_bioschemas('https://website.org', 'nbis-course-instances.json')

    source = sources(:unapproved_source)

    assert_nil source.test_results

    Sidekiq::Testing.inline! do
      SourceTestWorker.perform_async([source.id])
    end

    source.reload
    results = source.test_results

    assert results
    assert_equal 23, results[:events].length
    assert_equal 0, results[:materials].length
    sample = results[:events].detect { |e| e[:title] == 'Neural Networks and Deep Learning' }

    assert sample
    assert results[:run_time].positive?
    assert results[:finished_at] > 1.day.ago
  ensure
    path = source.send(:test_results_path)
    FileUtils.rm(path) if File.exist?(path)
  end

  test 'test source that returns an error code' do
    WebMock.stub_request(:get, 'https://website.org').to_return(status: 404)

    source = sources(:unapproved_source)

    assert_nil source.test_results

    Sidekiq::Testing.inline! do
      SourceTestWorker.perform_async([source.id])
    end

    source.reload
    results = source.test_results

    assert results
    assert_equal 0, results[:events].length
    assert_equal 0, results[:materials].length
    assert_includes results[:messages], "Couldn't open URL https://website.org: 404 "
    assert results[:run_time].positive?
    assert results[:finished_at] > 1.day.ago
  ensure
    path = source.send(:test_results_path)
    FileUtils.rm(path) if File.exist?(path)
  end

  test 'test source that throws an exception' do
    WebMock.stub_request(:get, 'https://website.org').to_return(status: 404)

    source = sources(:unapproved_source)

    assert_nil source.test_results

    Sidekiq::Testing.inline! do
      Ingestors::BioschemasIngestor.stub(:config, -> { raise StandardError, 'oh no' }) do
        assert_raises(StandardError) do
          SourceTestWorker.perform_async([source.id])
        end
      end
    end

    source.reload
    results = source.test_results

    assert results
    assert_equal 0, results[:events].length
    assert_equal 0, results[:materials].length
    assert_includes results[:messages], 'Ingestor encountered an unexpected error'
    assert results[:run_time].positive?
    assert results[:finished_at] > 1.day.ago
  ensure
    path = source.send(:test_results_path)
    FileUtils.rm(path) if File.exist?(path)
  end

  test 'gracefully handle testing a source that does not exist' do
    Sidekiq::Testing.inline! do
      assert_nothing_raised do
        SourceTestWorker.perform_async([Source.maximum(:id) + 100])
      end
    end
  end

  private

  def mock_bioschemas(url, filename)
    file = Rails.root.join('test', 'fixtures', 'files', 'ingestion', filename)
    WebMock.stub_request(:get, url).to_return(status: 200, headers: {}, body: file.read)
  end
end
