require 'test_helper'

class EventbriteIngestorTest < ActiveSupport::TestCase
  setup do
    @user = users(:regular_user)
    @content_provider = content_providers(:portal_provider)
    mock_ingestions
    mock_timezone # System time zone should not affect test result
  end

  teardown do
    reset_timezone
  end

  test 'can ingest events from eventbrite' do
    # enable source
    source = sources(:eventbrite_source)
    ingestor = Ingestors::EventbriteIngestor.new
    ingestor.token = source.token
    refute_nil source
    refute_nil source.token
    # set enabled
    source.enabled = true
    assert source.save

    assert_difference 'Event.count', 13 do
      freeze_time(2019) do
        ingestor.read(source.url)
        ingestor.write(@user, @content_provider)
      end
    end

    assert_equal 13, ingestor.events.count
    assert ingestor.materials.empty?
    assert_equal 13, ingestor.stats[:events][:added]
    assert_equal 0, ingestor.stats[:events][:updated]
    assert_equal 0, ingestor.stats[:events][:rejected]

    # check ingested event
    # eventbrite.id: 293623976217
    # timezone: "Australia/Perth", start: "2022-04-11T12:00:00", end: "2022-04-11T13:00:00"
    # status: live
    title = 'The Institutional Underpinnings Draft RDM Framework - Universities'
    url = 'https://www.eventbrite.com.au/e/the-institutional-underpinnings-draft-rdm-framework-universities-tickets-293623976217'
    desc = 'Learn about progress in the Institutional Underpinnings program and find out about how to give feedback on the draft framework.'
    event = get_event nil, title, url
    refute_nil event
    assert_equal desc, event.description
    assert_equal 'ARDC', event.organizer # organizer.name ARDC
    assert_empty event.event_types # format.name other
    assert_equal 'Perth', event.timezone
    assert_equal Time.utc(2022, 4, 11, 12, 0, 0).to_s, event.start.to_s
    assert_equal Time.utc(2022, 4, 11, 13, 0, 0).to_s, event.end.to_s
    assert_equal 300, event.capacity
    assert event.online
    assert_equal 'free', event.cost_basis
    assert_nil event.cost_currency # as cost_basis is free
    assert_empty event.keywords
    assert_nil event.venue

    # check completed event
    # eventbrite.id: 291075754417
    # status: completed
    title = 'The Institutional Underpinnings Draft RDM Framework - Universities'
    url = 'https://www.eventbrite.com.au/e/getting-started-with-nectar-research-cloud-training-tickets-291075754417'
    event = get_event nil, title, url
    assert_nil event

    # check draft event
    # eventbrite.id: 294940824947
    # status: draft
    title = 'TEST TEMPLATE TO COPY FOR ARDC EVENTS'
    url = 'https://www.eventbrite.com.au/e/test-template-to-copy-for-ardc-events-tickets-294940824947'
    event = get_event nil, title, url
    assert_nil event

    # check ingested event
    # eventbrite.id: 298980718377
    # category: 101 = Business & Professional
    # timezone: Australia/Sydney, start: 2022-05-03T13:30:00, end: 2022-05-03T15:00:00
    title = 'Sharing Sensitive and Identifiable Human Data'
    url = 'https://www.eventbrite.com.au/e/sharing-sensitive-and-identifiable-human-data-tickets-298980718377'
    desc = 'The ARDC Leadership Series is a new event series providing decision makers with an opportunity to work through big data challenges.'
    event = get_event nil, title, url
    refute_nil event
    assert_equal desc, event.description
    assert_equal 'Australian Research Data Commons', event.organizer
    assert_equal 'Sydney', event.timezone
    assert_equal Time.utc(2022, 5, 3, 13, 30, 0), event.start
    assert_equal Time.utc(2022, 5, 3, 15, 0, 0), event.end
    refute event.online
    assert_equal 'free', event.cost_basis
    assert_equal 'UNSW', event.venue
    assert_equal 'Sydney', event.city
    assert_equal 'Australia', event.country
    assert_equal '2052', event.postcode
    refute_empty event.event_types
    assert_equal 1, event.event_types.size
    assert_includes event.event_types, 'meetings_and_conferences'
    refute_empty event.keywords
    assert_equal 1, event.keywords.size
    refute_includes event.keywords, 'Business & Professional'
    assert_includes event.keywords, 'Other'
    refute_includes event.keywords, 'Dummy'
    assert_equal 1, event.target_audience.size
    assert_includes event.target_audience, 'Business & Professional'

    # check ingested event
    # eventbrite.id: 315896965327
    # category: 102 / 2004 = Science & Technology / High Tech
    # timezone: Australia/Sydney, start: 2022-06-01T13:00:00, end: 2022-06-01T15:00:00
    title = 'Getting Started with Nectar Research Cloud Training'
    url = 'https://www.eventbrite.com.au/e/getting-started-with-nectar-research-cloud-training-tickets-315896965327'
    desc = 'Learn the basics of using the **ARDC Nectar Cloud** for your research.'
    event = get_event nil, title, url
    refute_nil event
    assert_equal desc, event.description
    assert_equal 'Australian Research Data Commons', event.organizer
    assert_equal 'Sydney', event.timezone
    assert_equal Time.utc(2022, 6, 1, 13, 0, 0), event.start
    assert_equal Time.utc(2022, 6, 1, 15, 0, 0), event.end
    assert_equal 10, event.capacity
    assert event.online
    assert_equal 2, event.keywords.size
    assert_includes event.keywords, 'Science & Technology'
    assert_includes event.keywords, 'High Tech'

    # check ingested event
    # eventbrite.id: 298980718377
    # category: 101 = Business & Professional
    # timezone: Australia/Sydney, start: 2022-05-03T13:30:00, end: 2022-05-03T15:00:00
    title = 'Sharing Sensitive and Identifiable Human Data'
    url = 'https://www.eventbrite.com.au/e/sharing-sensitive-and-identifiable-human-data-tickets-298980718377'
    desc = 'The ARDC Leadership Series is a new event series providing decision makers with an opportunity to work through big data challenges.'
    event = get_event nil, title, url
    refute_nil event
    assert_equal desc, event.description
    assert_equal 'Australian Research Data Commons', event.organizer
    assert_equal 'Sydney', event.timezone
    assert_equal Time.utc(2022, 5, 3, 13, 30, 0), event.start
    assert_equal Time.utc(2022, 5, 3, 15, 0, 0), event.end

    # check source
    source = Source.where(url: 'https://www.eventbriteapi.com/v3/organizations/34338661734').first
    refute_nil source
  end

  private

  def get_event(id, title, url)
    return Event.find(id) unless id.nil?

    unless title.nil? or url.nil?
      events = Event.where(title: title, url: url)
      return events.first unless events.nil? or events.empty?
    end
  end
end
