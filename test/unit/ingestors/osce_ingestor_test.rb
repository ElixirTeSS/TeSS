require 'test_helper'

class OsceIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from osce' do
    source = @content_provider.sources.build(
      url: 'https://test',
      method: 'osce',
      enabled: true
    )

    ingestor = Ingestors::OsceIngestor.new

    # check event doesn't
    new_title = "Studium Generale: Work, Work, Work | The Invention and Future of Work - Jason Resnikoff"
    new_url = 'test'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 6 do
      freeze_time(Time.new(2019)) do
        VCR.use_cassette("ingestors/osce") do
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
    assert_equal 'OSCE', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Mon, 08 May 2023 20:00:00.000000000 UTC +00:00'.to_time, event.start
    assert_equal 'Mon, 08 May 2023 21:30:00.000000000 UTC +00:00'.to_time, event.end
    assert_equal 'Academy Building, Broerstraat 5, Groningen', event.location
    assert_nil event.end
  end
end
