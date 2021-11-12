# test/tasks/rake_task_automated_ingestion.rb

require 'test_helper'
require 'rake'

class RakeTasksAutomatedIngestion < ActiveSupport::TestCase

  setup do
    #puts "setup..."
    TeSS::Application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task['tess:automated_ingestion'].reenable
    override_config 'test_ingestion_example.yml'
    assert_equal 'production', TeSS::Config.ingestion[:name]
  end

  test 'default configuration file' do
    # set config file
    logfile = override_config 'test_ingestion.yml'
    assert !File.exist?(logfile)
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

    # check logfile
    assert File.exist?(logfile)
    assert File.readlines(logfile).grep(/ingestion file = test/).size > 0
  end

  test 'check user exists' do
    # set config file
    logfile = override_config 'test_ingestion_example.yml'
    assert_equal 'production', TeSS::Config.ingestion[:name]

    # check user does not exist
    user = User.find_by_username(TeSS::Config.ingestion[:username])
    assert user.nil?

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

    # check user exists
    user = User.find_by_username(TeSS::Config.ingestion[:username])
    assert !user.nil?
    assert_equal TeSS::Config.ingestion[:username], user.username
    assert_equal 'scraper_user', user.role.name
  end

  test 'check user created' do
    # set config file
    logfile = override_config 'test_ingestion.yml'
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # check user does not exist
    user = User.find_by_username(TeSS::Config.ingestion[:username])
    assert user.nil?

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

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
    Rake::Task['tess:automated_ingestion'].invoke
    assert check_task_finished(logfile)
  end

  test 'check first provider does not exist' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    assert !TeSS::Config.ingestion[:sources].nil?, "[#{config_file}] sources not found!"
    assert TeSS::Config.ingestion[:sources].size > 0, "[#{config_file}] sources is empty!"

    source = TeSS::Config.ingestion[:sources][0]
    assert !source.nil?
    slug = source[:provider]
    provider = ContentProvider.where(slug: slug).first
    assert provider.nil?

    # run task
    Rake::Task['tess:automated_ingestion'].invoke
    assert check_task_finished(logfile)
    error_message = "Provider[#{slug}\] not found!"
    # TODO: fix failing assertion
    # assert logfile_contains(logfile, error_message), "Error message '#{error}' not found in logfile!"
  end

  private

  def override_config (config_file)
    # switch configuration
    test_config_file = File.join(Rails.root, 'test', 'config', config_file)
    TeSS::Config.ingestion = YAML.safe_load(File.read(test_config_file)).deep_symbolize_keys!

    # clear log file
    logfile = File.join(Rails.root, TeSS::Config.ingestion[:logfile])
    File.delete(logfile) if !logfile.nil? and File.exist?(logfile)
    return logfile
  end

  def check_task_finished (logfile)
    logfile_contains logfile, 'Scraper.run: finish'
  end

  def logfile_contains(logfile, message)
    File.exist?(logfile) ? File.readlines(logfile).grep(Regexp.new message.encode(Encoding::UTF_8)).size > 0 : false
  end

end