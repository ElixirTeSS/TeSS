# test/tasks/rake_task_automated_ingestion.rb

require 'test_helper'
require 'rake'

class RakeTasksAutomatedIngestion < ActiveSupport::TestCase

  def setup
    TeSS::Application.load_tasks if Rake::Task.tasks.empty?
    @log_path = 'log/ingestions_test.log'
    File.delete(@log_path) if File.exists?(@log_path)
  end

  test 'without configuration file' do
    assert !File.exists?(@log_path)
    Rake::Task['tess:automated_ingestion'].invoke
    assert File.exists?(@log_path)
    assert File.readlines(@log_path).grep(/Could not load configuration. No such file/)
  end

end