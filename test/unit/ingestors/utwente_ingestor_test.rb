require 'test_helper'

class UtwenteIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from utwente' do
    source = @content_provider.sources.build(
      url: 'https://www.utwente.nl/en/events/?categories=417878',
      method: 'utwente',
      enabled: true
    )

    ingestor = Ingestors::UtwenteIngestor.new

    # check event doesn't
    new_title = 'Risk & Resilience Festival'
    new_url = 'https://www.utwente.nl/en/events/2023/11/925436/risk-resilience-festival'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 1 do
      freeze_time(2019) do
        VCR.use_cassette("ingestors/utwente") do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 1, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 1, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'University of Twente', event.organizer
    assert_equal Time.zone.parse('Thu, 09 Nov 2023 00:00:00 +0000'), event.start
    assert_equal Time.zone.parse('Thu, 09 Nov 2023 00:00:00 +0000'), event.end
    assert_equal 'Waaier', event.venue
  end
end
