require 'test_helper'

class FourtuWillmaLlmIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from 4tu' do
    source = @content_provider.sources.build(
      url: 'https://www.4tu.nl/en/agenda/',
      method: '4tu',
      enabled: true
    )

    ingestor = Ingestors::FourtuLlmIngestor.new

    # check event doesn't
    new_title = '4TU-meeting National Technology Strategy'
    refute Event.where(title: new_title).any?

    mock_llm_requests
    # run task
    assert_difference 'Event.count', 1 do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/4tu_willma_llm') do
          with_settings({ llm_scraper: { model: 'willma', model_version: 'Zephyr 7B' } }) do
            ingestor.read(source.url)
            ingestor.write(@user, @content_provider)
          end
        end
      end
    end

    assert_equal 2, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 1, ingestor.stats[:events][:added]
    assert_equal 1, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title).first
    assert event
    assert_equal new_title, event.title

    # check other fields
    assert_equal Time.zone.parse('Wed, 3 Jul 2024 12:30:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Wed, 3 Jul 2024 19:00:00.000000000 UTC +00:00'), event.end
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Basecamp, Nijverheidsweg 16A, 3534 AM Utrecht (https://basecamputrecht.nl)', event.venue
    assert_equal 'LLM', event.source
  end
end
