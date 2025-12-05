require 'test_helper'

class RDNLIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from rdnl' do
    source = @content_provider.sources.build(
      url: 'https://.knaw.nl/en/agenda/?filter=true&page=',
      method: 'rdnl',
      enabled: true
    )

    ingestor = Ingestors::Taxila::RdnlIngestor.new

    # check event doesn't
    new_title = 'Essentials 4 Data Support, Feb/Mar 2026'
    new_url = 'https://researchdata.nl/agenda/essentials-4-data-support-feb-mar-2026/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 1 do
      freeze_time(2025) do
        VCR.use_cassette('ingestors/rdnl') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 1, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 1, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'RDNL', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'DANS-KNAW', event.venue
    assert_equal Time.zone.parse('Tue, 10 Feb 2026 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Mon, 26 Mar 2026 17:00:00.000000000 UTC +00:00'), event.end
  end
end
