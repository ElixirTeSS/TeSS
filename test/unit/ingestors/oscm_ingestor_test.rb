require 'test_helper'

class OscmIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from oscm' do
    source = @content_provider.sources.build(
      url: 'https://www.openscience-maastricht.nl/events/',
      method: 'oscm',
      enabled: true
    )

    ingestor = Ingestors::OscmIngestor.new

    # check event doesn't
    new_title = 'FAIR Coffee lecture - Gijs van Dijck'
    new_url = 'https://www.openscience-maastricht.nl/events/fair-coffee-lecture-24-may-2023/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 3 do
      freeze_time(2019) do
        VCR.use_cassette("ingestors/oscm") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 3, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 3, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'FAIR Coffee lecture - Gijs van Dijck', event.title
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'OSCM', event.source
    assert event.online?
    assert_equal Time.zone.parse('Wed, 24 May 2023 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Wed, 24 May 2023 10:00:00.000000000 UTC +00:00'), event.end
  end
end
