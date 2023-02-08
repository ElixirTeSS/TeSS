require 'test_helper'

class WurIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from wur' do
    source = @content_provider.sources.build(
      url: 'https://www.wur.nl/en/Resources-1/RSS/Calendar.htm',
      method: 'wur',
      enabled: true
    )

    ingestor = Ingestors::WurIngestor.new

    # run task
    freeze_time(Time.new(2019)) do
      VCR.use_cassette("ingestors/wur") do
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
