require 'test_helper'

class LeidenIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from leiden' do
    source = @content_provider.sources.build(
      url: 'https://www.library.universiteitleiden.nl/events',
      method: 'leiden',
      enabled: true
    )

    ingestor = Ingestors::LeidenIngestor.new

    # check event doesn't
    new_title = 'Workshop: How to write a Data Management Plan (DMP)'
    new_url = 'https://www.library.universiteitleiden.nl/events/2023/07/workshop-how-to-write-a-data-management-plan-dmp'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 9 do
      freeze_time(2019) do
        VCR.use_cassette("ingestors/leiden") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 9, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 9, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal Time.zone.parse('Thu, 6 Jul 2023 14:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Thu, 6 Jul 2023 16:30:00.000000000 UTC +00:00'), event.end
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'University Library', event.venue
    assert_equal 'Universiteit Leiden', event.source
  end
end
