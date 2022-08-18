# test/tasks/rake_task_event_rest.rb

require 'test_helper'

class RakeTaskExampleIngestion < ActiveSupport::TestCase

  setup do
    #puts "setup..."
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

  test 'validate example ingestion file' do
    # set config file
    config_file = 'test_ingestion_example.yml'
    logfile = override_config config_file

    # check config file parameters
    assert_equal 'production', TeSS::Config.ingestion[:name]
    assert_equal 'scraper', TeSS::Config.ingestion[:username]

    # run task
    freeze_time(stub_time = Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check logfile messages
    message = 'User created: username\[scraper\] role\[scraper_user\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message

    message = 'Validation error: Provider not found: dummyP'
    assert logfile_contains(logfile, message), 'Message not found: ' + message

    message = 'Validation error: Method is invalid: dummyM'
    assert logfile_contains(logfile, message), 'Message not found: ' + message

    message = 'Validation error: Resource type is invalid: dummyR'
    assert logfile_contains(logfile, message), 'Message not found: ' + message

    message = 'Validation error: URL not accessible: https://dummy.com'
    assert logfile_contains(logfile, message), 'Message not found: ' + message

  end

end
