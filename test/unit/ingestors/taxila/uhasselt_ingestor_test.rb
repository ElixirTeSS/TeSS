require 'test_helper'

class UhasseltIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone
  end

  test 'can ingest events from uhasselt' do
    source = @content_provider.sources.build(
      url: 'https://bibliotheek.uhasselt.be/nl/resources#kalender',
      method: 'uhasselt',
      enabled: true
    )

    ingestor = Ingestors::Taxila::UhasseltIngestor.new

    # check event doesn't
    new_title = 'Tidy data part 1: How to structure your data | March 2026'
    new_url = 'https://www.uhasselt.be/en/university-library/research/research-data-management/training-calendar-rdm/tidy-data-part-1-how-to-structure-your-data-march-2026'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 10 do
      freeze_time(2023) do
        VCR.use_cassette("ingestors/uhasselt") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 10, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 10, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'UHasselt', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal Time.zone.parse('Mon, 16 Mar 2026 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Mon, 16 Mar 2026 17:00:00.000000000 UTC +00:00'), event.end
    assert_equal 'campus Diepenbeek', event.venue
    refute event.online?
  end
end
