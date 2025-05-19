require 'test_helper'

class MaastrichtIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
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

    ingestor = Ingestors::Taxila::MaastrichtIngestor.new

    # check event doesn't
    new_title = 'Qualitative FAIR Data'
    new_url = 'https://library.maastrichtuniversity.nl/events/qualitative-fair-data-4/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 43 do
      freeze_time(2019) do
        VCR.use_cassette("ingestors/maastricht") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 43, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 43, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Maastricht', event.city
    assert_equal Time.zone.parse('Mon, 16 Jun 2025 10:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Mon, 16 Jun 2025 12:00:00.000000000 UTC +00:00'), event.end
  end
end
