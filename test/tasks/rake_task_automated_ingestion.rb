# test/tasks/rake_task_automated_ingestion.rb

require 'test_helper'

class RakeTasksAutomatedIngestion < ActiveSupport::TestCase

  setup do
    #puts "setup..."
    mock_ingestions
    TeSS::Application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task['tess:automated_ingestion'].reenable
    override_config 'test_ingestion_example.yml'
    assert_equal 'production', TeSS::Config.ingestion[:name]
    TeSS::Config.dictionaries['eligibility'] = 'eligibility_dresa.yml'
    EligibilityDictionary.instance.reload
  end

  test 'default configuration file' do
    # set config file
    logfile = override_config 'test_ingestion.yml'
    assert !File.exist?(logfile)
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # run task
    freeze_time(stub_time = Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check logfile
    assert File.exist?(logfile), "logfile[#{logfile}] missing"
    assert logfile_contains(logfile, 'ingestion file = test')
  end

  test 'check user exists' do
    # set config file
    logfile = override_config 'test_ingestion_example.yml'
    assert_equal 'production', TeSS::Config.ingestion[:name]

    # check user does not exist
    user = User.find_by_username(TeSS::Config.ingestion[:username])
    assert user.nil?

    # run task
    freeze_time(stub_time = Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check user exists
    user = User.find_by_username(TeSS::Config.ingestion[:username])
    assert !user.nil?
    assert_equal TeSS::Config.ingestion[:username], user.username
    assert_equal 'scraper_user', user.role.name
  end

  test 'check user has role scraper_user' do
    # set config file
    logfile = override_config 'test_ingestion_bad.yml'
    assert_equal 'dummy', TeSS::Config.ingestion[:name]

    # check user does exist
    user = User.find_by_username(TeSS::Config.ingestion[:username])
    assert !user.nil?
    assert !user.role.nil?
    assert_equal 'registered_user', user.role.name

    # run task
    freeze_time(stub_time = Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check ingestion config rejected: bad user role
    assert File.exist?(logfile)
    assert logfile_contains(logfile, 'Validation error: User has invalid role')
  end

  test 'check user created' do
    # set config file
    logfile = override_config 'test_ingestion.yml'
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # check user does not exist
    user = User.find_by_username(TeSS::Config.ingestion[:username])
    assert user.nil?

    # run task
    freeze_time(stub_time = Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check user exists
    user = User.find_by_username(TeSS::Config.ingestion[:username])
    assert !user.nil?
    assert_equal TeSS::Config.ingestion[:username], user.username
    assert_equal 'scraper_user', user.role.name
  end

  test 'check contains at least one source' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    assert !TeSS::Config.ingestion[:sources].nil?, "[#{config_file}] sources not found!"
    assert TeSS::Config.ingestion[:sources].size > 0, "[#{config_file}] sources is empty!"

    # run task
    freeze_time(stub_time = Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    assert check_task_finished(logfile)
  end

  test 'check missing provider fails validation' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    assert !TeSS::Config.ingestion[:sources].nil?, "[#{config_file}] sources not found!"
    assert TeSS::Config.ingestion[:sources].size > 0, "[#{config_file}] sources is empty!"

    source = TeSS::Config.ingestion[:sources][0]
    assert !source.nil?
    title = source[:provider]
    provider = ContentProvider.find_by_title(title)
    assert provider.nil?

    # run task
    freeze_time(stub_time = Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    assert check_task_finished(logfile)
    error_message = 'Validation error: Provider not found: ' + title.to_s
    assert logfile_contains(logfile, error_message), "Error message '#{error_message}' not found in logfile!"
  end

  test 'check valid provider does not error' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    assert !TeSS::Config.ingestion[:sources].nil?, "[#{config_file}] sources not found!"
    assert TeSS::Config.ingestion[:sources].size > 1, "[#{config_file}] sources is empty!"

    source = TeSS::Config.ingestion[:sources][1]
    assert !source.nil?
    title = source[:provider]
    provider = ContentProvider.find_by_title(title)
    assert !provider.nil?, "Provider title[#{title}] not found!"

    # run task
    freeze_time(stub_time = Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    assert check_task_finished(logfile)
    error_message = 'Provider not found: ' + title.to_s
    assert !logfile_contains(logfile, error_message), "Unexpected error message: #{error_message}"
  end

  test 'check for invalid source parameters' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # run task
    freeze_time(stub_time = Time.new(2019)) do ||
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check validation errors
    error_message = 'Provider not found: Dummy Provider'
    assert logfile_contains(logfile, error_message), 'Error message not found: ' + error_message
    error_message = 'URL not accessible: https://dummy.com/events.csv'
    assert logfile_contains(logfile, error_message), 'Error message not found: ' + error_message
    error_message = 'Method is invalid: xtc'
    assert logfile_contains(logfile, error_message), 'Error message not found: ' + error_message
    error_message = 'Resource type is invalid: workflow'
    assert logfile_contains(logfile, error_message), 'Error message not found: ' + error_message
  end

end