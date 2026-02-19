require 'test_helper'

class SurfIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from surf' do
    source = @content_provider.sources.build(
      url: 'https://www.surf.nl/agenda',
      method: 'surf',
      enabled: true
    )

    ingestor = Ingestors::Taxila::SurfIngestor.new

    # check event doesn't
    new_title = 'SURF Onderwijsdagen 2026'
    new_url = 'https://www.surf.nl/agenda#surf_onderwijsdagen_2026'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 20 do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/surf') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 20, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 20, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'SURF', event.source
    refute event.online?
    assert_equal Time.zone.parse('Wed, 10 Nov 2026 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Thu, 11 Nov 2026 17:00:00.000000000 UTC +00:00'), event.end
    assert_equal "Amare, Spuiplein 150, 2511 DG Den Haag", event.venue
  end
end
