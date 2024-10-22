require 'test_helper'

class OdisseiIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from odissei' do
    source = @content_provider.sources.build(
      url: 'https://odissei-data.nl/calendar/',
      method: 'odissei',
      enabled: true
    )

    ingestor = Ingestors::OdisseiIngestor.new

    # check event doesn't
    new_title = 'ODISSEI Conference 2024'
    new_url = 'https://odissei-data.nl/event/odissei-conference-2024/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 4 do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/odissei') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 4, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 4, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'ODISSEI', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal Time.zone.parse('Tue, 10 Dec 2019 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Tue, 10 Dec 2019 17:00:00.000000000 UTC +00:00'), event.end
    assert_equal 'Jaarbeurs', event.venue
    refute event.online?
  end
end
