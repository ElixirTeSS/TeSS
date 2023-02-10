require 'test_helper'

class WurIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from wur' do
    source = @content_provider.sources.build(
      url: 'https://www.wur.nl/en/Resources-1/RSS/Calendar.htm',
      method: 'wur',
      enabled: true
    )

    ingestor = Ingestors::WurIngestor.new

    # check event doesn't
    new_title = ' Genetic Diversity - key to transitions in agriculture and forestry '
    new_url = 'https://www.wur.nl/en/activity/genetic-diversity-key-to-transitions-in-agriculture-and-forestry-1.htm'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 24 do
      freeze_time(Time.new(2016)) do
        VCR.use_cassette("ingestors/wur") do
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
    assert_equal 'WUR', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Wed, 15 Mar 2023 11:00:00.000000000 UTC +00:00'.to_time, event.start
    assert_equal 'Fri, 01 Jan 2016 17:00:00.000000000 UTC +00:00'.to_time, event.end
  end
end
