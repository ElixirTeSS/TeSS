# frozen_string_literal: true

require 'test_helper'

class RugIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from rug' do
    source = @content_provider.sources.build(
      url: 'https://www.rug.nl/about-ug/latest-news/events/calendar/',
      method: 'rug',
      enabled: true
    )

    ingestor = Ingestors::RugIngestor.new

    # check event doesn't
    new_title = 'Studium Generale: Work, Work, Work | The Invention and Future of Work - Jason Resnikoff'
    new_url = 'https://www.rug.nl/about-ug/latest-news/events/calendar/studium-generale/work-jason-resnikoff'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 7 do
      freeze_time(Time.new(2019).utc) do
        VCR.use_cassette('ingestors/rug') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 7, ingestor.events.count
    assert_empty ingestor.materials
    assert_equal 7, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'RUG', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Mon, 08 May 2023 20:00:00.000000000 UTC +00:00'.to_time, event.start
    assert_equal 'Mon, 08 May 2023 21:30:00.000000000 UTC +00:00'.to_time, event.end
    assert_equal 'Academy Building, Broerstraat 5, Groningen', event.venue
  end
end
