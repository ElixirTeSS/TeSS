require 'test_helper'

class DtlsIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from dtls' do
    source = @content_provider.sources.build(
      url: 'https://www.dtls.nl/',
      method: 'dtls',
      enabled: true
    )

    ingestor = Ingestors::DtlsIngestor.new

    # check event doesn't
    new_title = 'Constraint-based modeling: Introduction and advanced topics'
    new_url = 'https://www.dtls.nl/?post_type=course&p=19311'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 4 do
      freeze_time(2019) do
        VCR.use_cassette('ingestors/dtls') do
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
    assert_equal 'Constraint-based modeling: Introduction and advanced topics', event.title
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'Wageningen Campus', event.city
    assert_equal 'Netherlands', event.country
    assert_equal Time.zone.parse('Mon, 13 Feb 2023 09:00:00.000000000 UTC +00:00'), event.start
    assert_equal Time.zone.parse('Fri, 17 Feb 2023 17:00:00.000000000 UTC +00:00'), event.end
  end
end
