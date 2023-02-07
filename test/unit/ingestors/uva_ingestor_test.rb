require 'test_helper'

class UvaIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from uva' do
    source = @content_provider.sources.build(
      url: 'https://www.uva.nl/_restapi/list-json?uuid=def191e0-f85f-4ba0-b618-ee6d16f36db4&mount=13a4adcb-039a-4e99-b085-e9d91c8c7dc1',
      method: 'uva',
      enabled: true
    )

    ingestor = Ingestors::UvaIngestor.new

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
