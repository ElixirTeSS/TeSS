# frozen_string_literal: true

require 'test_helper'

class UuIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from uu' do
    source = @content_provider.sources.build(
      url: 'https://www.uu.nl/events.rss?category-containers=4293,4295,4296,4301,2162490',
      method: 'uu',
      enabled: true
    )

    ingestor = Ingestors::UuIngestor.new

    # check event doesn't
    new_title = 'Inloopspreekuur voor alle vragen over research data en software - week 13 2023'
    new_url = 'https://www.uu.nl/agenda/inloopspreekuur-voor-alle-vragen-over-research-data-en-software-230327'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 57 do
      freeze_time(Time.new(2016).utc) do
        VCR.use_cassette('ingestors/uu') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 58, ingestor.events.count
    assert_empty ingestor.materials
    assert_equal 57, ingestor.stats[:events][:added]
    assert_equal 1, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'UU', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Mon, 27 Mar 2023 13:00:00.000000000 UTC +00:00'.to_time, event.start
    assert_equal 'Mon, 27 Mar 2023 15:00:00.000000000 UTC +00:00'.to_time, event.end
  end
end
