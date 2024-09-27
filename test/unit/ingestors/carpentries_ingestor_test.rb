require 'test_helper'

class CarpentriesIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from upcoming SWC workshops feed' do
    source = @content_provider.sources.build(
      url: 'https://feeds.carpentries.org/swc_upcoming_workshops.json',
      method: 'carpentries',
      enabled: true
    )

    ingestor = Ingestors::CarpentriesIngestor.new

    # run task
    assert_difference 'Event.count', 2 do
      freeze_time(2024) do
        VCR.use_cassette('ingestors/carpentries_swc') do
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

    event = Event.where(url: 'https://dexwel.github.io/2024-08-12-NiTheCS-Online').first
    assert event
    assert_equal 'Carpentries Mix & Match', event.title
    assert_equal(-26.19162, event.latitude.to_f.round(5))
    assert_equal 28.03107, event.longitude.to_f.round(5)
    assert_equal 'South Africa', event.country
    assert_equal 'The National Institute for Theoretical and Computational Sciences - NITheCS', event.venue
    assert_equal Time.zone.parse('12 Aug 2024 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('16 Aug 2024 17:00:00.000000000 UTC +00:00'), event.end
    assert_equal ['National Institute for Theoretical and Computational Sciences'], event.host_institutions
    assert event.online?
  end
end
