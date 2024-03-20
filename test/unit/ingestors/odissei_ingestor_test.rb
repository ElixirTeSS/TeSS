# frozen_string_literal: true

require 'test_helper'

class OdisseiIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from odissei' do
    source = @content_provider.sources.build(
      url: 'https://odissei-data.nl/calendar/',
      method: 'odissei',
      enabled: true
    )

    ingestor = Ingestors::OdisseiIngestor.new

    # check event doesn't
    new_title = 'SICSS – ODISSEI Summer School 2023'
    new_url = 'https://odissei-data.nl/calendar/sicss-odissei-summer-school-2023/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 2 do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/odissei') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    assert_equal 2, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 2, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'ODISSEI', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal Time.zone.parse('Mon, 19 Jun 2023 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Fri, 30 Jun 2023 17:00:00.000000000 UTC +00:00'), event.end
    assert_equal 'Erasmus University Rotterdam', event.venue
    refute event.online?
  end
end
