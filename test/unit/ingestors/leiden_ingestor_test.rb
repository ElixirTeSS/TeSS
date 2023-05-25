# frozen_string_literal: true

require 'test_helper'

class LeidenIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from leiden' do
    source = @content_provider.sources.build(
      url: 'https://www.library.universiteitleiden.nl/events',
      method: 'leiden',
      enabled: true
    )

    ingestor = Ingestors::LeidenIngestor.new

    # check event doesn't
    new_title = 'Data Carpentry Workshop for the Social Sciences'
    new_url = 'https://www.library.universiteitleiden.nl/events/2023/02/data-carpentry-workshop'

    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 15 do
      freeze_time(Time.new(2019).utc) do
        VCR.use_cassette('ingestors/leiden') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 15, ingestor.events.count
    assert_empty ingestor.materials
    assert_equal 15, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first

    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'Mon, 20 Feb 2023 00:00:00.000000000 UTC +00:00'.to_time, event.start
    assert_equal 'Fri, 24 Feb 2023 00:00:00.000000000 UTC +00:00'.to_time, event.end
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Online only', event.venue
    assert_equal 'Universiteit Leiden', event.source
  end
end
