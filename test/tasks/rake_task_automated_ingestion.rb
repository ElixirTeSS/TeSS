# test/tasks/rake_task_automated_ingestion.rb

require 'test_helper'
require 'rake'

class RakeTasksAutomatedIngestion < ActiveSupport::TestCase

  def setup
    TeSS::Application.load_tasks if Rake::Task.tasks.empty?
    puts "config = #{TeSS::Config.ingestion}"
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

  private

  def override_config (config_file)
    # switch configuration
    test_config_file = File.join(Rails.root, 'test', 'config', config_file)
    test_ingest = YAML.safe_load(File.read(test_config_file)).deep_symbolize_keys!
    TeSS::Config.ingestion = test_ingest

    # clear log file
    logfile = File.join(Rails.root, TeSS::Config.ingestion[:logfile] )
    File.delete(logfile) if !logfile.nil? and File.exist?(logfile)
    return logfile
  end

end