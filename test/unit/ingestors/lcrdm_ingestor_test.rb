# frozen_string_literal: true

require 'test_helper'

class LcrdmIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from lcrdm' do
    source = @content_provider.sources.build(
      url: 'https://lcrdm.nl/evenementen/',
      method: 'lcrdm',
      enabled: true
    )

    ingestor = Ingestors::LcrdmIngestor.new

    # check event doesn't
    new_title = 'UKB/LCRDM Networking day'
    new_url = 'https://lcrdm.nl/evenementen/ukb-lcrdm-networking-day/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 2 do
      freeze_time(Time.new(2023).utc) do
        VCR.use_cassette('ingestors/lcrdm') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 2, ingestor.events.count
    assert_empty ingestor.materials
    assert_equal 2, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'LCRDM', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Thu, 25 May 2023 09:30:00.000000000 UTC +00:00'.to_time, event.start
    assert_equal 'Thu, 25 May 2023 17:00:00.000000000 UTC +00:00'.to_time, event.end
    assert_equal 'Maastricht University', event.venue
  end
end
