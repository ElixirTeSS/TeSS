require 'test_helper'

class UuIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from uu' do
    source = @content_provider.sources.build(
      url: 'https://www.uu.nl/events.rss?category-containers=4293,4295,4296,4301,2162490&date=2017-01-30',
      method: 'uu',
      enabled: true
    )

    ingestor = Ingestors::UuIngestor.new

    # check event doesn't
    new_title = 'Oud-minister Ben Bot verzorgt eerste Geremek Lezing over toekomst van de EU'
    new_url = 'https://www.uu.nl/agenda/oud-minister-ben-bot-verzorgt-eerste-geremek-lezing-over-toekomst-van-de-eu'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 20 do
      freeze_time(Time.new(2016)) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
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
    assert_equal 'UU', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal '2010 12 13', event.start
    assert_equal '2010 12 13', event.end
  end
end
