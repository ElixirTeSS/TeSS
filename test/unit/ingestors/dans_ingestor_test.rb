require 'test_helper'

class DansIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from dans' do
    source = @content_provider.sources.build(
      url: 'https://dans.knaw.nl/en/past-events/&%20NDE%20Annual&%20NDE%20Annual%20Conference%202022?filter=true&s=Topics%20in%20Heritage%20Science',
      method: 'dans',
      enabled: true
    )

    ingestor = Ingestors::DansIngestor.new

    # check event doesn't
    new_title = 'The lecture series “Current Topics in Heritage Science” #5:'
    new_url = 'https://www.iperionhs.eu/hs-academy-lecture-05/'
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
    assert_equal 'DANS', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal ['Archeology'], event.keywords
    assert_equal '19 January 2023'.to_time, event.start
    assert_equal '', event.end
  end
end
