require 'test_helper'

class NwoIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from nwo' do
    source = @content_provider.sources.build(
      url: 'https://www.nwo.nl/en/meetings',
      method: 'nwo',
      enabled: true
    )

    ingestor = Ingestors::NwoIngestor.new

    # check event doesn't
    new_title = 'NWO Biophysics'
    new_url = 'https://www.nwo.nl/en/meetings/biophysics'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 24 do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/nwo') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 24, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 24, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'NWO Biophysics', event.title
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'NWO', event.source
    assert_equal Time.zone.parse('Mon, 09 Oct 2023 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Tue, 10 Oct 2023 17:00:00.000000000 UTC +00:00'), event.end
  end
end
