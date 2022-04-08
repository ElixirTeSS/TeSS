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
    freeze_time(stub_time = Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check event does exist
    events = Event.where(title: new_title, url: new_url)
    assert !events.nil?, "Post-task: events search error."
    assert_equal 1, events.size, "Post-task: events search title[Another Event] found nothing"
    event = events.first
    assert !event.nil?
    assert_equal new_title, event.title
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
    source.enabled = true
    assert source.save

    # run task
    assert_difference 'Event.count', 1 do
      freeze_time(stub_time = Time.new(2019)) do ||
        Rake::Task['tess:automated_ingestion'].invoke
      end

      # TODO: check ingested events

    end

    # TODO: check logfile messages

  end

end
