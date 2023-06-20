require 'test_helper'

class UhassoltIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from uhasselt' do
    source = @content_provider.sources.build(
      url: 'https://bibliotheek.uhasselt.be/nl/resources#kalender',
      method: 'uhasselt',
      enabled: true
    )

    ingestor = Ingestors::UhasseltIngestor.new

    # check event doesn't
    new_title = 'Data Management Plan - DMP writing session'
    new_url = 'http://bibliotheek.uhasselt.be/nl/een-woordje-uitleg-over-onze-opleidingen#WritingDMP'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 14 do
      freeze_time(Time.new('2023-06-18')) do
        VCR.use_cassette("ingestors/uhasselt") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 14, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 14, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'UHasselt', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Tue, 03 Oct 2023 13:00:00.000000000 UTC +00:00'.to_time, event.start
    assert_equal 'Tue, 03 Oct 2023 15:00:00.000000000 UTC +00:00'.to_time, event.end
    assert_equal 'Campus Diepenbeek CD-D A54', event.venue
    assert_equal false, event.online
  end
end
