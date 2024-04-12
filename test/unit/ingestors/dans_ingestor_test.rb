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

    ingestor = Ingestors::DansIngestor.new

    # check event doesn't
    new_title = 'Open Hour SSH: live Q&A on Monday'
    new_url = 'https://dans.knaw.nl/en/agenda/open-hour-ssh-live-qa-on-monday-2/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 6 do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/dans') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 6, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 6, ingestor.stats[:events][:added]
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
    assert_equal ['Social Sciences and Humanities', 'Training &amp; Outreach', 'Consultancy'], event.keywords
    assert_equal Time.zone.parse('Mon, 13 Feb 2023 09:00:00.000000000 UTC +00:00'), event.start
    assert_nil event.end
  end
end
