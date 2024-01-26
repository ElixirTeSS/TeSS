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
      url: 'https://www.surf.nl/sitemap.xml',
      method: 'surf',
      enabled: true
    )

    ingestor = Ingestors::SurfIngestor.new

    # check event doesn't
    new_title = 'Master class Privacy Assessment Framework'
    new_url = 'https://www.surf.nl/en/agenda/masterclass-review-framework-privacy-apr-1'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 52 do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/surf') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 52, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 52, ingestor.stats[:events][:added]
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
    assert event.online?
    assert_equal Time.zone.parse('Thu, 25 Apr 2024 12:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Thu, 25 Apr 2024 12:00:00.000000000 UTC +00:00'), event.end
  end
end
