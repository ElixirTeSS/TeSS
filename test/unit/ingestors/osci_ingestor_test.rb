# frozen_string_literal: true

require 'test_helper'

class OsciIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from osci' do
    source = @content_provider.sources.build(
      url: 'https://osc-international.com/my-calendar/',
      method: 'osci',
      enabled: true
    )

    ingestor = Ingestors::OsciIngestor.new

    # check event doesn't
    new_title = '14:00: Open Science Coffee: Assessing robustness through multiverse analysis – Applications in research and education'
    new_url = 'https://osc-international.com/my-calendar/?format=calendar&month=9&yr=2023#mc_calendar_03_2-calendar-details-my-calendar'

    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 12 do
      freeze_time(2023) do
        VCR.use_cassette('ingestors/osci') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 18, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 12, ingestor.stats[:events][:added]
    assert_equal 6, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'OSCI', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal Time.zone.parse('Sun, 03 Sep 2023 14:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Sun, 03 Sep 2023 15:00:00.000000000 UTC +00:00'), event.end
    assert_equal 'OSC Leiden', event.venue
  end
end
