require 'test_helper'

class LeidenIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from elixir tess' do
    source = @content_provider.sources.build(
      url: 'https://www.library.universiteitleiden.nl/events?year=2022&month=6&day=3',
      method: 'leiden',
      enabled: true
    )

    ingestor = Ingestors::LeidenIngestor.new

    # check event doesn't
    new_title = 'Master PH student-for-a-day | June 3rd'
    new_url = 'https://www.library.universiteitleiden.nl/events/2022/06/phm-student-for-a-day---3-june'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 1 do
      freeze_time(Time.new(2019)) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
      end
    end

    assert_equal 1, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 1, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'June 3rd 2022 09:00', event.start
    assert_equal 'June 3rd 2022 13:00', event.end
    assert_equal 'Europe/Amsterdam', event.timezone
    assert_equal 'Wijnhaven: Turfmarkt 99, 2511 DP The Hague', event.venue
    assert_equal 'Universiteit Leiden', event.source
  end
end
