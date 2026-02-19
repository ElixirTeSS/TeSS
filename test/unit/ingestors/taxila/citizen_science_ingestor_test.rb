require 'test_helper'

class CitizenScienceIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone
  end

  test 'can ingest events from citizen_science' do
    source = @content_provider.sources.build(
      url: 'https://citizenscience.nl/events/',
      method: 'citizen_science',
      enabled: true
    )

    ingestor = Ingestors::Taxila::CitizenScienceIngestor.new

    # check event doesn't
    new_title = 'High-Level Policy Event on the Sustainability of Citizen Science'
    new_url = 'https://events.teams.microsoft.com/event/47581424-c548-4f07-928a-9fed358df416@659b3608-37a1-406b-9e1a-02c011decd3c'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 13 do
      freeze_time(2023) do
        VCR.use_cassette("ingestors/citizen_science") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 13, ingestor.events.count
    assert_equal 13, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'CitizenScience', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal Time.zone.parse('Mon, 19 Feb 2026 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Mon, 19 Feb 2026 10:00:00.000000000 UTC +00:00'), event.end
    assert_equal 'Online', event.venue
    assert event.online?
  end

  test 'can ingest materials from citizen_science' do
    source = @content_provider.sources.build(
      url: 'https://citizenscience.nl/events/',
      method: 'citizen_science',
      enabled: true
    )

    ingestor = Ingestors::Taxila::CitizenScienceIngestor.new

    # check event doesn't
    new_title = 'Naar een vaste plek voor burgerwetenschap in het netwerk van openbare bibliotheken'
    new_url = 'https://www.citizenscience.nl/resource/475'
    refute Material.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Material.count', 25 do
      freeze_time(2023) do
        VCR.use_cassette("ingestors/citizen_science") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 33, ingestor.materials.count
    assert_equal 25, ingestor.stats[:materials][:added]
    assert_equal 8, ingestor.stats[:materials][:updated]
    assert_equal 0, ingestor.stats[:materials][:rejected]

    # check material does exist
    material = Material.where(title: new_title, url: new_url).first
    assert material
    assert_equal new_title, material.title
    assert_equal new_url, material.url
  end
end
