require 'test_helper'

class MaastrichtIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone('Australia/Adelaide') # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from maastricht' do
    source = @content_provider.sources.build(
      url: 'https://library.maastrichtuniversity.nl/events/',
      method: 'maastricht',
      enabled: true
    )

    ingestor = Ingestors::MaastrichtIngestor.new

    # check event doesn't
    new_title = 'What journal to publish in'
    new_url = 'https://library.maastrichtuniversity.nl/events/what-journal-to-publish-in/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 23 do
      freeze_time(2019) do
        VCR.use_cassette("ingestors/maastricht") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 23, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 23, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'What journal to publish in', event.title
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Maastricht', event.city
    assert_equal Time.zone.parse('Mon, 14 Feb 2023 11:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Fri, 14 Feb 2023 12:30:00.000000000 UTC +00:00'), event.end
  end
end
