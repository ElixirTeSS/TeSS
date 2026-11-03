require 'test_helper'

class UtwenteIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from utwente' do
    source = @content_provider.sources.build(
      url: 'https://www.utwente.nl/en/about-us/news-events-ceremonies/events/',
      method: 'utwente',
      enabled: true
    )

    ingestor = Ingestors::Taxila::UtwenteIngestor.new

    # check event doesn't
    new_title = 'Let’s make peace work'
    new_url = 'https://www.utwente.nl/en/about-us/news-events-ceremonies/events/2026/9/996952/lets-make-peace-work'
    refute Event.where(title: new_title, url: new_url).any?

    # run task, cassette covers 2 pages (skip: 0, then skip: 10) to exercise pagination
    assert_difference 'Event.count', 2 do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/utwente') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 2, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 2, ingestor.stats[:events][:added]
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
    assert_equal Time.zone.parse('Tue, 22 Sep 2026 19:30:00 +0000'), event.start
    assert_equal Time.zone.parse('Tue, 22 Sep 2026 21:00:00 +0000'), event.end
    assert_equal 'Vrijhof - Amphitheater', event.venue

    # second page came through too
    assert Event.where(title: 'Founding Father of ASML – Martin van den Brink').any?
  end
end
