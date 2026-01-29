require 'test_helper'

class HanIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from han' do
    source = @content_provider.sources.build(
      url: 'https://www.han.nl/studeren/scholing-voor-werkenden/laboratorium/',
      method: 'han',
      enabled: true
    )

    ingestor = Ingestors::Taxila::HanIngestor.new

    # check events don't exist
    new_title = 'Synthetiseren en Karakteriseren van Moleculen'
    new_url = 'https://www.han.nl/opleidingen/module/synthetiseren-karakteriseren-moleculen/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference('Event.count', 15) do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/han') do
          ingestor.read(source.url)
          ingestor.write(@user, @content_provider)
        end
      end
    end

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    assert_equal 'HAN', event.source
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Nijmegen Laan van Scheut 2', event.venue
    assert_equal Time.zone.parse('Mon, 1 Feb 2026 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Mon, 1 Feb 2026 17:00:00.000000000 UTC +00:00'), event.end
  end
end
