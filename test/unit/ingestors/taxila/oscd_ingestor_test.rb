require 'test_helper'

class OscdIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from oscd' do
    source = @content_provider.sources.build(
      url: 'https://osc-delft.github.io/events',
      method: 'oscd',
      enabled: true
    )

    ingestor = Ingestors::Taxila::OscdIngestor.new

    # check event doesn't
    new_title = 'Opening up a Flow battery by Sanli Faez'
    new_url = 'https://osc-delft.github.io/events#opening_up_a_flow_battery_by_sanli_faez'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 4 do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/oscd') do
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
    assert_equal 'OSCD', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal Time.zone.parse('Tue, 21 Jan 2019 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Tue, 21 Jan 2019 17:00:00.000000000 UTC +00:00'), event.end
    assert_equal 'Online - Register here', event.venue
    assert event.online?
  end
end
