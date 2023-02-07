require 'test_helper'

class UtwenteIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from elixir tess' do
    source = @content_provider.sources.build(
      url: 'https://www.utwente.nl/en/events/?startdate=2022-01-01&enddate=2022-01-10',
      method: 'utwente',
      enabled: true
    )

    ingestor = Ingestors::UtwenteIngestor.new

    # check event doesn't
    new_title = "New Year's event 2022"
    new_url = 'https://www.utwente.nl/en/events/2022/1/322102/new-years-event-2022'
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
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'University of Twente', event.organizer
    assert_equal '2022-01-10 09:00:00', event.start
    assert_equal '2022-01-10 10:00:00', event.end
    assert event.online
    assert_equal 'Online', event.venue
  end
end
