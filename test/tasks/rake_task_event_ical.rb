# test/tasks/rake_task_event_rest.rb

require 'test_helper'

class RakeTaskEventIcal < ActiveSupport::TestCase

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

  test 'sitemap not found' do
    # set config file
    config_file = 'test_ingestion_ical.yml'
    logfile = override_config config_file
    assert_equal 'ical_event', TeSS::Config.ingestion[:name]
    event_count = Event.all.size

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

  end

end
