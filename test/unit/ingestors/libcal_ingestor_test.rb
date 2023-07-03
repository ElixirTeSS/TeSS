require 'test_helper'

class LibcalIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from libcal' do
    source = @content_provider.sources.build(
      url: 'https://vu-nl.libcal.com/ajax/calendar/list?c=7052&date=2022-01-10&perpage=48&page=1&audience=&cats=&camps=&inc=0',
      method: 'libcal',
      enabled: true
    )

    ingestor = Ingestors::LibcalIngestor.new

    # check event doesn't
    new_title = 'ENDNOTE LIGHT'
    new_url = 'https://vu-nl.libcal.com/event/3826342'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 1 do
      freeze_time(2019) do
        VCR.use_cassette("ingestors/libcal") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
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
    assert_equal 'Rick Vermunt', event.organizer
    assert_equal Time.zone.parse('Mon, 10 Jan 2022 13:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Mon, 10 Jan 2022 15:00:00.000000000 UTC +00:00'), event.end
    assert_equal '', event.venue
    assert_equal 'Netherlands', event.country
    assert_equal 'VU Amsterdam', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal true, event.online
  end
end
