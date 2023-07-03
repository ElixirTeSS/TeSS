require 'test_helper'

class TessEventIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:another_portal_provider)
    mock_ingestions
  end

  test 'can ingest events from elixir tess' do
    source = @content_provider.sources.build(
      url: 'https://tess.elixir-europe.org/events?include_expired=false&content_provider[]=Australian BioCommons',
      method: 'tess_event',
      enabled: true
    )

    ingestor = Ingestors::TessEventIngestor.new

    # check event doesn't
    new_title = 'WORKSHOP: Introduction to Metabarcoding using Qiime2'
    new_url = 'https://www.biocommons.org.au/events/metabarcoding-qiime2'
    refute Event.where(title: new_title, url: new_url).any?

    # run task
    assert_difference 'Event.count', 2 do
      freeze_time(2019) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
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
    assert_equal 'Another Portal Provider', event.content_provider.title
    assert_equal 'UTC', event.timezone
    assert_equal 'Melissa Burke (melissa@biocommons.org.au)', event.contact
    assert_equal 'Australian BioCommons', event.organizer
    assert_equal 1, event.eligibility.size, 'event eligibility size not matched!'
    assert event.eligibility.include?('registration_of_interest')
    assert_equal 1, event.host_institutions.size
    assert event.host_institutions.include?('Australian Biocommons')
    assert_equal 4, event.keywords.size
    assert event.online
    assert_equal '', event.city
    assert_equal 'Australia', event.country
    assert_equal 'Online', event.venue

    # check another event does exist
    other_title = 'WEBINAR: Establishing Gen3 to enable better human genome data sharing in Australia'
    other_url = 'https://www.biocommons.org.au/events/gen3-webinar'
    events = Event.where(title: other_title, url: other_url)
    assert !events.nil?, 'Post-task: other event search error.'
    assert_equal 1, events.size, "Post-task: other event search title[#{other_title}] found nothing"
    event = events.first
    assert !event.nil?
    # noinspection RubyNilAnalysis
    assert_equal other_title, event.title
    assert_equal other_url, event.url
  end
end
