require 'test_helper'

class DansIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from dans' do
    source = @content_provider.sources.build(
      url: 'https://dans.knaw.nl/en/agenda/?filter=true&page=',
      method: 'dans',
      enabled: true
    )

    ingestor = Ingestors::Taxila::DansIngestor.new

    # check event doesn't
    new_title = 'Open Science Festival 2025'
    new_url = 'https://opensciencefestival.nl/en/register-as-a-participant'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 11 do
      freeze_time(2025) do
        VCR.use_cassette('ingestors/dans') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 11, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 11, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'DANS', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal ['FAIR and Open data'], event.keywords
    assert_equal Time.zone.parse('Mon, 24 Oct 2025 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Mon, 24 Oct 2025 17:00:00.000000000 UTC +00:00'), event.end
  end
end
