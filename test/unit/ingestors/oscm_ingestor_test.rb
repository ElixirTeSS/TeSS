require 'test_helper'

class OscmIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from oscm' do
    source = @content_provider.sources.build(
      url: 'https://www.openscience-maastricht.nl/events/',
      method: 'oscm',
      enabled: true
    )

    ingestor = Ingestors::OscmIngestor.new

    # run task
    freeze_time(Time.new(2019)) do
      ingestor.read(source.url)
      ingestor.write(@user, @content_provider)
    end

    assert ingestor.events.count > 0
    assert ingestor.stats[:events][:added] > 0
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]
  end
end
