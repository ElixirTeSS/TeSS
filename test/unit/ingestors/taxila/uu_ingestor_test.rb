require 'test_helper'

class UuIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from uu' do
    source = @content_provider.sources.build(
      url: 'https://www.uu.nl/en/events.rss?category-containers=5457932,5457933,5457934',
      method: 'uu',
      enabled: true
    )

    ingestor = Ingestors::Taxila::UuIngestor.new

    # check event doesn't
    new_title = 'Re-Inventing Policies and Institutions for Inclusive Labour Markets in Europe and Beyond'
    new_url = 'https://www.uu.nl/en/events/re-inventing-policies-and-institutions-for-inclusive-labour-markets-in-europe-and-beyond'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 48 do
      freeze_time(2016) do
        VCR.use_cassette("ingestors/uu") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 54, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 48, ingestor.stats[:events][:added]
    assert_equal 6, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'UU', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal Time.zone.parse('Mon, 08 Sep 2025 07:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Tue, 09 Sep 2025 15:00:00.000000000 UTC +00:00'), event.end
  end
end
