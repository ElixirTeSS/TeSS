# test/tasks/automated_ingestion_test.rb

require 'test_helper'

class ScraperTest < ActiveSupport::TestCase
  setup do
    mock_ingestions
    Source.delete_all
  end

  def run
    with_dresa_dictionaries do
      super
    end
  end

  test 'default configuration file' do
    # set config file
    scraper = Scraper.new(load_scraper_config('test_ingestion.yml'))
    assert_equal 'test', scraper.name

    # run task
    freeze_time(2019) do
      scraper.run
    end

    logfile = scraper.log_file
    assert File.exist?(logfile), "logfile[#{logfile}] missing"
    assert logfile_contains(logfile, 'ingestion file = test')
  end

  test 're-use existing user' do
    existing = users(:scraper_user)
    config = load_scraper_config('test_ingestion_example.yml').merge(username: existing.username)
    scraper = Scraper.new(config)
    assert_equal 'production', scraper.name

    # check user exists
    user = User.find_by_username(scraper.username)
    assert user

    # run task
    assert_no_difference('User.count') do
      freeze_time(2019) do
        scraper.run
      end
    end

    # check user exists
    user = User.find_by_username(scraper.username)
    assert user
    assert_equal config[:username], user.username
    assert_equal 'scraper_user', user.role.name
  end

  test 'check user has role scraper_user' do
    # set config file
    scraper = Scraper.new(load_scraper_config('test_ingestion_bad.yml'))
    assert_equal 'dummy', scraper.name

    # check user does exist
    user = User.find_by_username(scraper.username)
    refute user.nil?
    refute user.role.nil?
    assert_equal 'registered_user', user.role.name

    # run task
    freeze_time(2019) do
      scraper.run
    end

    logfile = scraper.log_file
    # check ingestion config rejected: bad user role
    assert File.exist?(logfile)
    assert logfile_contains(logfile, 'Validation error: User has invalid role')
  end

  test 'create user if does not exist' do
    # set config file
    config = load_scraper_config('test_ingestion.yml')
    scraper = Scraper.new(config)
    assert_equal 'test', scraper.name

    # check user does not exist
    user = User.find_by_username(scraper.username)
    assert_nil user

    # run task
    assert_difference('User.count', 1) do
      freeze_time(2019) do
        scraper.run
      end
    end

    # check user exists
    user = User.find_by_username(scraper.username)
    assert user
    assert_equal config[:username], user.username
    assert_equal 'scraper_user', user.role.name
  end

  test 'check contains at least one source' do
    # set config file
    config = load_scraper_config('test_ingestion.yml')
    scraper = Scraper.new(config)
    logfile = scraper.log_file
    assert_equal 'test', scraper.name
    assert scraper.sources.size > 0

    # run task
    freeze_time(2019) do
      scraper.run
    end

    assert check_task_finished(logfile)
  end

  test 'check missing provider fails validation' do
    # set config file
    config = load_scraper_config('test_ingestion.yml')
    scraper = Scraper.new(config)
    logfile = scraper.log_file
    assert_equal 'test', scraper.name
    assert scraper.sources.size > 0

    source = scraper.sources[0]
    refute source.nil?
    title = source[:provider]
    provider = ContentProvider.find_by_title(title)
    assert provider.nil?

    # run task
    freeze_time(2019) do
      scraper.run
    end

    assert check_task_finished(logfile)
    error_message = 'Validation error: Provider not found: ' + title.to_s
    assert logfile_contains(logfile, error_message), "Error message '#{error_message}' not found in logfile!"
  end

  test 'check valid provider does not error' do
    # set config file
    config = load_scraper_config('test_ingestion.yml')
    scraper = Scraper.new(config)
    logfile = scraper.log_file
    assert_equal 'test', scraper.name
    assert scraper.sources.size > 1

    source = scraper.sources[1]
    refute source.nil?
    title = source[:provider]
    provider = ContentProvider.find_by_title(title)
    refute provider.nil?, "Provider title[#{title}] not found!"

    # run task
    freeze_time(2019) do
      scraper.run
    end

    assert check_task_finished(logfile)
    error_message = 'Content provider must exist: ' + title.to_s
    refute logfile_contains(logfile, error_message), "Unexpected error message: #{error_message}"
  end

  test 'check for invalid source parameters' do
    # set config file
    config = load_scraper_config('test_ingestion.yml')
    scraper = Scraper.new(config)
    logfile = scraper.log_file
    assert_equal 'test', scraper.name

    # run task
    freeze_time(2019) do
      scraper.run
    end

    # check validation errors
    error_message = 'Provider not found: Dummy Provider'
    assert logfile_contains(logfile, error_message), 'Error message not found: ' + error_message
    error_message = 'URL not accessible: https://dummy.com/events.csv'
    assert logfile_contains(logfile, error_message), 'Error message not found: ' + error_message
    error_message = 'Method is invalid: xtc'
    assert logfile_contains(logfile, error_message), 'Error message not found: ' + error_message
  end

  test 'handles non-user ingestion methods' do
    with_settings(user_ingestion_methods: ['bioschemas']) do
      config = load_scraper_config('test_ingestion.yml')
      scraper = Scraper.new(config)
      logfile = scraper.log_file
      assert_equal 'test', scraper.name

      freeze_time(2019) do
        scraper.run
      end

      refute logfile_contains(logfile, 'Method is not included in the list: event_csv')
      refute logfile_contains(logfile, 'Method is not included in the list: material_csv')
    end
  end

  test 'does not crash for legacy config' do
    logfile = nil
    Kernel.silence_warnings do
      config = load_scraper_config('test_ingestion_legacy.yml')
      scraper = Scraper.new(config)
      logfile = scraper.log_file
      assert_equal 'legacy', scraper.name

      freeze_time(2019) do
        scraper.run
      end
    end

    refute logfile_contains(logfile, 'Run Scraper failed with')
    assert logfile_contains(logfile, 'Method is invalid: rest')
  end

  test 'logs backtrace on error' do
    config = load_scraper_config('test_ingestion_crash.yml')
    scraper = Scraper.new(config)
    logfile = scraper.log_file
    assert_equal 'crash', scraper.name

    Ingestors::IngestorFactory.stub(:get_ingestor, -> { raise 'oh no' }) do
      scraper.run
    end

    assert logfile_contains(logfile, 'Run Scraper failed with')
    assert logfile_contains(logfile, 'in `block in run')
    assert logfile_contains(logfile, 'in `map')
    assert logfile_contains(logfile, 'in `run')
  end

  test 'does not scrape disabled or unapproved sources' do
    WebMock.stub_request(:get, /https:\/\/app.com\/\d/).to_return(status: 200,
      body: File.open(Rails.root.join('test', 'fixtures', 'files', 'ingestion', 'events.csv')))

    scraper = Scraper.new(load_scraper_config('test_ingestion_disabled.yml'))
    provider = content_providers(:goblet)
    user = users(:admin)
    unapproved_source = provider.sources.create!(url: 'https://app.com/2', method: 'event_csv', user: user,
                                                 enabled: true, approval_status: 'not_approved')
    approval_requested_source = provider.sources.create!(url: 'https://app.com/3', method: 'event_csv', user: user,
                                                         enabled: true, approval_status: 'requested')
    User.current_user = user # Admin is required to save approved status
    enabled_source = provider.sources.create!(url: 'https://app.com/1', method: 'event_csv', user: user,
                                              enabled: true, approval_status: 'approved')
    disabled_source = provider.sources.create!(url: 'https://app.com/4', method: 'event_csv', user: user,
                                               enabled: false, approval_status: 'approved')

    scraper.run

    logfile = scraper.log_file
    # From Config
    assert logfile_contains(logfile, "Source URL[https://app.com/events/sitemap.xml]")
    refute logfile_contains(logfile, "Source URL[https://app.com/events/disabled.xml]")
    # From Database
    assert logfile_contains(logfile, "Source URL[#{enabled_source.url}]")
    refute logfile_contains(logfile, "Source URL[#{disabled_source.url}]")
    refute logfile_contains(logfile, "Source URL[#{unapproved_source.url}]")
    refute logfile_contains(logfile, "Source URL[#{approval_requested_source.url}]")
  end

  test 'scrape a specific source' do
    provider = content_providers(:portal_provider)
    source = Source.create!(url: 'https://somewhere.com/stuff', method: 'bioschemas',
                            enabled: true, approval_status: 'approved',
                            content_provider: provider, user: users(:admin))
    file = Rails.root.join('test', 'fixtures', 'files', 'ingestion', 'nbis-course-instances.json')
    WebMock.stub_request(:get, source.url).to_return(status: 200, headers: {}, body: file.read)
    scraper = Scraper.new

    refute provider.events.where(url: 'https://uppsala.instructure.com/courses/75565').exists?
    assert_difference('provider.events.count', 23) do
      scraper.scrape(source)
    end
    assert provider.events.where(url: 'https://uppsala.instructure.com/courses/75565').exists?
    source.reload
    assert_equal 23, source.records_read
    assert_equal 23, source.records_written
    assert_equal 23, source.resources_added
    assert_equal 0, source.resources_updated
    assert_equal 0, source.resources_rejected
    assert source.finished_at > 1.day.ago
    assert_includes source.log, 'Bioschemas summary'
    assert_includes source.log, '- CourseInstances: 23'
  end

  private

  def check_task_finished(logfile)
    logfile_contains logfile, 'Scraper.run: finish'
  end

  def logfile_contains(logfile, message)
    if logfile.is_a?(IO)
      logfile.rewind
      logfile.readlines.any? { |l| message.is_a?(Regexp) ? l.match(message) : l.include?(message) }
    else
      return false unless File.exist?(logfile)

      File.readlines(logfile).any? { |l| message.is_a?(Regexp) ? l.match(message) : l.include?(message) }
    end
  end

  def load_scraper_config(config_file)
    test_config_file = File.join(Rails.root, 'test', 'config', config_file)
    YAML.safe_load(File.read(test_config_file)).deep_symbolize_keys!
  end
end
