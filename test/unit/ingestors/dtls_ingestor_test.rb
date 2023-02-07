require 'test_helper'

class DtlsIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from dtls' do
    source = @content_provider.sources.build(
      url: 'https://www.dtls.nl/courses/?s=integrated_modeling_and_optimization&filter_course=archive',
      method: 'dtls',
      enabled: true
    )

    ingestor = Ingestors::DtlsIngestor.new

    # check event doesn't
    new_title = 'Interated Modeling and Optimization (Fundamental)'
    new_url = 'https://www.dtls.nl/courses/integrated-modeling-and-optimization-2022/'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 3 do
      freeze_time(Time.new(2019)) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
      end
    end

    assert_equal 3, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 3, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check event does exist
    event = Event.where(title: new_title, url: new_url).first
    assert event
    assert_equal new_title, event.title
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'Integrated Modeling and Optimization (Fundamental)', event.title
    assert_equal 'Amsterdam', event.timezone
    assert_equal 'BioSB reseach schoor & TU Eindhoven', event.organizer
    assert_equal 'Wageningen', event.city
    assert_equal 'Netherlands', event.country
    assert_equal '2022-12-12 09:00:00', event.start
    assert_equal '2022-12-16 17:00:00', event.end
  end
end
