# test/tasks/rake_task_event_rest.rb

require 'test_helper'

class RakeTaskEventRest < ActiveSupport::TestCase

  setup do
    mock_ingestions
    TeSS::Application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task['tess:automated_ingestion'].reenable
    override_config 'test_ingestion_example.yml'
    assert_equal 'production', TeSS::Config.ingestion[:name]
    TeSS::Config.dictionaries['eligibility'] = 'eligibility_dresa.yml'
    EligibilityDictionary.instance.reload
    TeSS::Config.dictionaries['event_types'] = 'event_types_dresa.yml'
    EventTypeDictionary.instance.reload
    TeSS::Config.dictionaries['licences'] = 'licences_dresa.yml'
    LicenceDictionary.instance.reload
  end

  test 'check ingestion event from TeSS Elixir-Europe source' do
    # set config file
    config_file = 'test_ingestion_rest_event.yml'
    logfile = override_config config_file
    assert_equal 'rest_event', TeSS::Config.ingestion[:name]

    # check event doesn't
    new_title = 'WORKSHOP: Introduction to Metabarcoding using Qiime2'
    new_url = 'https://www.biocommons.org.au/events/metabarcoding-qiime2'
    events = Event.where(title: new_title, url: new_url)
    assert !events.nil?, "Pre-task: events search error."
    assert_equal 0, events.size, "Pre-task: events search title[Another Event] found something"

    # run task
    freeze_time(Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check event does exist
    events = Event.where(title: new_title, url: new_url)
    assert !events.nil?, "Post-task: events search error."
    assert_equal 1, events.size, "Post-task: events search title[Another Event] found nothing"
    event = events.first
    assert !event.nil?
    assert_respond_to event, :title
    #noinspection RubyNilAnalysis
    assert_equal new_title, event.title
    assert_respond_to event, :url
    assert_equal new_url, event.url

    # check other fields
    assert_equal 'Another Portal Provider', event.content_provider.title
    assert_equal 'UTC', event.timezone
    assert_equal 'Melissa Burke (melissa@biocommons.org.au)', event.contact
    assert_equal 'Australian BioCommons', event.organizer
    assert_equal 1, event.eligibility.size, "event eligibility size not matched!"
    assert event.eligibility.include?('expression_of_interest')
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
    assert !events.nil?, "Post-task: other event search error."
    assert_equal 1, events.size, "Post-task: other event search title[#{other_title}] found nothing"
    event = events.first
    assert !event.nil?
    #noinspection RubyNilAnalysis
    assert_equal other_title, event.title
    assert_equal other_url, event.url

    # check logfile messages
    message = 'events processed\[2\] added\[2\] updated\[0\] rejected\[0\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Source URL\[https://tess.elixir-europe.org/events\?include_expired=false\&content_provider\[\]=Australian BioCommons\] resources read\[2\] and written\[2\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

  test 'test ingestion of event from Eventbrite source' do
    # set config file
    config_file = 'test_ingestion_rest_eventbrite.yml'
    logfile = override_config config_file
    assert_equal 'rest_eventbrite', TeSS::Config.ingestion[:name]

    # enable source
    source = sources :eventbrite_source
    refute_nil source
    refute_nil source.token
    # set enabled
    source.enabled = true
    assert source.save

    assert_difference 'Event.count', 13 do
      # run task
      freeze_time(Time.new(2022, 01, 01)) do ||
        Rake::Task['tess:automated_ingestion'].invoke
      end
    end

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
    assert_equal Time.new(2022, 04, 11, 12, 00, 00), event.start
    assert_equal Time.new(2022, 04, 11, 13, 00, 00), event.end
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
    assert_equal Time.new(2022, 05, 03, 13, 30, 0), event.start
    assert_equal Time.new(2022, 05, 03, 15, 0, 0), event.end
    refute event.online
    assert_equal 'free', event.cost_basis
    assert_equal 'UNSW', event.venue
    assert_equal 'Sydney', event.city
    assert_equal 'Australia', event.country
    assert_equal '2052', event.postcode
    refute_empty event.event_types
    assert_equal 1, event.event_types.size
    assert_includes event.event_types, 'conference'
    refute_empty event.keywords
    assert_equal 2, event.keywords.size
    assert_includes event.keywords, 'Business & Professional'
    assert_includes event.keywords, 'Other'
    refute_includes event.keywords, 'Dummy'

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
    assert_equal Time.new(2022, 06, 01, 13, 00, 0), event.start
    assert_equal Time.new(2022, 06, 01, 15, 0, 0), event.end
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
    assert_equal Time.new(2022, 05, 03, 13, 30, 0), event.start
    assert_equal Time.new(2022, 05, 03, 15, 0, 0), event.end

    # check source
    sources = Source.where(url: 'https://www.eventbriteapi.com/v3/organizations/34338661734')
    refute_nil sources
    refute_empty sources
    source = sources.first
    refute_nil source
    assert_respond_to source, :log
    #noinspection RubyNilAnalysis
    refute_nil source.log
    message = 'Eventbrite events ingestor: records read[18] inactive[5] expired[0]'
    assert_includes source.log, message

    # check logfile messages
    message = 'Source URL\[https://www.eventbriteapi.com/v3/organizations/34338661734\] resources read\[13\] and written\[13\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
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
