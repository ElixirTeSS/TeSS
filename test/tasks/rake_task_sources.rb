# test/tasks/rake_task_sources.rb

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
    config_file = 'test_ingestion_sources.yml'
    logfile = override_config config_file
    assert_equal 'sources', TeSS::Config.ingestion[:name]

    assert_difference 'Event.count', 19 do
      # override time
      freeze_time(stub_time = Time.new(2021)) do ||
        # run task
        Rake::Task['tess:automated_ingestion'].invoke
      end
    end

    # check logfile message
    message = 'Sources processed = 6'
    assert logfile_contains(logfile, message), 'Message found: ' + message

    # check updated source records
    # TODO: check output
  end

end