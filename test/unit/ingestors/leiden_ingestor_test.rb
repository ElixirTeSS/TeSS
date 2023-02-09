require 'test_helper'

class LeidenIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from leiden' do
    source = @content_provider.sources.build(
      url: 'https://www.library.universiteitleiden.nl/events?year=2022&month=6&day=3',
      method: 'leiden',
      enabled: true
    )

    ingestor = Ingestors::LeidenIngestor.new

    # check event doesn't
    new_title = 'Faculty Career Orientation Days (FLO) 2023'
    new_url = 'https://www.library.universiteitleiden.nl/events/2023/02/faculty-career-orientation-days-flo-2023'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 15 do
      freeze_time(Time.new(2019)) do
        VCR.use_cassette("ingestors/leiden") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 15, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 15, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'Tue, 07 Feb 2023 00:00:00 +0000'.to_time, event.start
    assert_equal 'Wed, 08 Feb 2023 00:00:00 +0000'.to_time, event.start
    assert_equal 'Europe/Amsterdam', event.timezone
    assert_equal 'Pieter de la Court', event.venue
    assert_equal 'Universiteit Leiden', event.source
  end
end
