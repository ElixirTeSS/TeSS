require 'test_helper'

class TdccIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from tdcc' do
    prev_tz = ENV['TZ']  # Time zone should not affect test result
    ENV['TZ'] = 'America/Barbados'
    source = @content_provider.sources.build(
      url: 'https://tdcc.nl/evenementen/',
      method: 'tdcc',
      enabled: true
    )

    ingestor = Ingestors::TdccIngestor.new

    # check event doesn't
    new_title = "Open Science Festival Maastricht"
    new_url = 'https://tdcc.nl/evenementen/open-science-festival-maastricht/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 4 do
      freeze_time(Time.new(2023)) do
        VCR.use_cassette("ingestors/tdcc") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 4, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 4, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'TDCC', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Thu, 25 May 2023 09:00:00.000000000 UTC +00:00'.to_time, event.start
    assert_equal 'Thu, 25 May 2023 18:00:00.000000000 UTC +00:00'.to_time, event.end
    assert_equal 'School of Business and Economics (SBE) in MaastrichtTongersestraat 536211 LM Maastricht', event.venue
  ensure
    ENV['TZ'] = prev_tz
  end
end
