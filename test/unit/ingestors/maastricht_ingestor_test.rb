require 'test_helper'

class MaastrichtIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from maastricht' do
    source = @content_provider.sources.build(
      url: 'https://library.maastrichtuniversity.nl/events/',
      method: 'maastricht',
      enabled: true
    )

    ingestor = Ingestors::MaastrichtIngestor.new

    # run task
    freeze_time(Time.new(2019)) do
      VCR.use_cassette("ingestors/maastricht") do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
      end
    end

    assert ingestor.events.count > 0
    assert ingestor.stats[:events][:added] > 0
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]
  end
end
