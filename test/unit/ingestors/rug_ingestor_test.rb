require 'test_helper'

class RugIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from rug' do
    source = @content_provider.sources.build(
      url: 'https://www.rug.nl/about-ug/latest-news/events/calendar/',
      method: 'rug',
      enabled: true
    )

    ingestor = Ingestors::RugIngestor.new

    # check event doesn't
    new_title = "Studium Generale: Work, Work, Work | The Invention and Future of Work - Jason Resnikoff"
    new_url = 'https://www.rug.nl/about-ug/latest-news/events/calendar/studium-generale/work-jason-resnikoff'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 7 do
      freeze_time(2019) do
        VCR.use_cassette("ingestors/rug") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 7, ingestor.events.count
    assert ingestor.materials.empty?
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
    assert_equal Time.zone.parse('Mon, 08 May 2023 20:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Mon, 08 May 2023 21:30:00.000000000 UTC +00:00'), event.end
    assert_equal 'Academy Building, Broerstraat 5, Groningen', event.venue
  end


  test 'can ingest events from rug in various timezones' do
    source = @content_provider.sources.build(
      url: 'https://www.rug.nl/about-ug/latest-news/events/calendar/',
      method: 'rug',
      enabled: true
    )

    ingestor = Ingestors::RugIngestor.new
    # check event doesn't exist
    new_title = "Studium Generale: Work, Work, Work | The Invention and Future of Work - Jason Resnikoff"
    new_url = 'https://www.rug.nl/about-ug/latest-news/events/calendar/studium-generale/work-jason-resnikoff'
    refute Event.where(title: new_title, url: new_url).any?

    # Scrape the initial events
    assert_difference 'Event.count', 7 do
      freeze_time(2016) do
        VCR.use_cassette("ingestors/rug") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    year = 2016
    ['Europe/London', 'Asia/Damascus', 'Australia/Adelaide', 'America/Barbados'].each do |timezone|
      ingestor = Ingestors::RugIngestor.new # Reset ingestor
      mock_timezone(timezone)
      year += 1

      assert_no_difference 'Event.count' do
        freeze_time(year) do
          VCR.use_cassette("ingestors/rug") do
            ingestor.read(source.url)
            ingestor.write(@user, @content_provider)
          end
        end
      end

      assert_equal 7, ingestor.events.count
      assert_equal 0, ingestor.stats[:events][:added]
      assert_equal 7, ingestor.stats[:events][:updated]
      assert_equal 0, ingestor.stats[:events][:rejected]

      # Get last updated event
      event = Event.where(title: new_title, url: new_url).last
      assert event
      assert_equal new_title, event.title
      assert_equal new_url, event.url
      assert_equal year, event.last_scraped.year

      # check other fields
      assert_equal 'RUG', event.source
      assert_equal 'Amsterdam', event.timezone
      assert_equal Time.zone.parse('Mon, 08 May 2023 20:00:00.000000000 UTC +00:00'), event.start
      assert_equal Time.zone.parse('Mon, 08 May 2023 21:30:00.000000000 UTC +00:00'), event.end
      assert_equal 'Academy Building, Broerstraat 5, Groningen', event.venue
    end
  end
end
