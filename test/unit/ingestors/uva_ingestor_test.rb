# frozen_string_literal: true

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

    # check event doesn't
    new_title = 'The Societal Impact of AI & Data Science'
    new_url = 'https://uba.uva.nl/en/shared/subsites/data-science-centre/en/events/2023/03/the-societal-impact-of-ai-and-data-science.html?origin=ht%2ByU3HqRAGnIsBBlkOh%2Fw'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 9 do
      freeze_time(Time.new(2016).utc) do
        VCR.use_cassette('ingestors/uva') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 9, ingestor.events.count
    assert_empty ingestor.materials
    assert_equal 9, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'UvA', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Mon, 24 Mar 2023 10:00:00.000000000 UTC +00:00'.to_time, event.start
    assert_equal 'Mon, 24 Mar 2023 12:30:00.000000000 UTC +00:00'.to_time, event.end
  end
end
