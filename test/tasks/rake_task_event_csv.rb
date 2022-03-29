# test/tasks/rake_task_event_ingestion.rb

require 'test_helper'

class RakeTasksEventCSVIngestion < ActiveSupport::TestCase

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

  test 'check ingestion and validation of events from csv file' do
    # set config file
    config_file = 'test_ingestion_csv.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # override time
    freeze_time(stub_time = Time.new(2021)) do ||
      # run task
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check logfile message
    message = 'IngestorEventCsv: failed with: Illegal quoting'
    refute logfile_contains(logfile, message), 'Message found: ' + message

    # check an entry
    title = 'Introduction to Gadi'
    url = 'https://opus.nci.org.au/display/Help/Introduction+to+Gadi'
    description = 'Introduction to Gadi is designed for new users, or users that want a refresher on the basics of Gadi.'
    events = Event.where(title: title)
    refute events.nil?, "No events found for title[#{title}] url[#{url}] not found"
    event = events.first
    assert_equal description, event.description, "Event title[#{title}] not matched"
    assert_equal url, event.url

    # check logfile messages
    message = 'events processed\[14\] added\[14\] updated\[0\] rejected\[0\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    url = 'https://raw.githubusercontent.com/nci900/NCI_feed_to_DReSA/master/event_NCI.csv'
    message = 'resources read\[14\] and written\[14\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

end