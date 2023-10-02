require 'test_helper'

class SenseIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from sense' do
    source = @content_provider.sources.build(
      url: 'https://sense.nl/event/page/2/?wpv_view_count=177',
      method: 'sense',
      enabled: true
    )

    ingestor = Ingestors::SenseIngestor.new

    # check event doesn't
    new_title = "Reinventing the city; Scientific Conference AMS Institute"
    new_url = "https://sense.nl/event/reinventing-the-city-scientific-conference-ams-institute/"
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 14 do
      freeze_time(2019) do
        VCR.use_cassette("ingestors/sense") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 14, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 14, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'Sense', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal Time.zone.parse('Tue, 23 Apr 2024 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Thu, 25 Apr 2024 17:00:00.000000000 UTC +00:00'), event.end
    assert_equal 'Amsterdam', event.venue
  end
end
