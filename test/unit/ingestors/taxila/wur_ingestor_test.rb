require 'test_helper'

class WurIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from wur' do
    source = @content_provider.sources.build(
      url: 'https://www.wur.nl/en/news-insights/activities-at-wur',
      method: 'wur',
      enabled: true
    )

    ingestor = Ingestors::Taxila::WurIngestor.new

    # check event doesn't
    new_title = 'Prying Genomes: Providing a molecular foundation for oyster restoration'
    new_url = 'https://www.wur.nl/en/activity/prying-genomes-providing-molecular-foundation-oyster-restoration'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 62 do
      freeze_time(2016) do
        VCR.use_cassette("ingestors/wur") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 62, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 62, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'WUR', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Omnia - Building 105', event.venue
    assert_equal Time.zone.parse('2026-08-24 09:00:00'), event.start
    assert_equal Time.zone.parse('2026-08-24 17:00:00'), event.end
  end
end
