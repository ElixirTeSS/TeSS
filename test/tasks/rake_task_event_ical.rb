# test/tasks/rake_task_event_rest.rb

require 'test_helper'

class RakeTaskEventIcal < ActiveSupport::TestCase

  setup do
    mock_ingestions
    mock_nominatim
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

  test 'sitemap not found' do
    # set config file
    config_file = 'test_ingestion_ical.yml'
    logfile = override_config config_file
    assert_equal 'ical_event', TeSS::Config.ingestion[:name]

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

    # post task validation
    # check logfile messages for source #1
    message = 'Validation error: URL not accessible: https://missing.org/sitemap.xml'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

  test 'invalid source definition' do
    # set config file
    config_file = 'test_ingestion_ical.yml'
    logfile = override_config config_file
    assert_equal 'ical_event', TeSS::Config.ingestion[:name]

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

    # post task validation
    # check logfile messages for source #2
    message = 'Ingestor not yet implemented for method\[ical\] and resource\[material\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

  test 'ingest valid sitemap' do
    # set config file
    config_file = 'test_ingestion_ical.yml'
    logfile = override_config config_file
    assert_equal 'ical_event', TeSS::Config.ingestion[:name]
    event_count = Event.all.size
    assert_equal 21, event_count, 'Pre-task: event count not matched.'

    # override time
    freeze_time(stub_time=Time.new(2020)) do ||
      # run task
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # post task validation
    added = 4; updated = 2; rejected = 2;

    # check individual events
    # TODO: check not found
    message = 'process file url\[https://pawsey.org.au/events/\?ical=true\] failed with: 404'
    assert logfile_contains(logfile, message), 'Message not found: ' + message

    # TODO: check added

    # TODO: check updated

    # TODO: check rejected

    # TODO: check totals
    assert_equal event_count + added, Event.all.size, 'Post-task: event count not matched.'
    message = "IngestorEventIcal: events added[#{added}] updated[#{updated}] rejected[#{rejected}]"
    assert logfile_contains(logfile, message), 'Message not found: ' + message

  end



end
