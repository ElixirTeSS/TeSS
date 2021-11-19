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
    Rake::Task['tess:automated_ingestion'].invoke

    # check logfile
    assert File.exist?(logfile)
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
    Rake::Task['tess:automated_ingestion'].invoke

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
    Rake::Task['tess:automated_ingestion'].invoke

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
    Rake::Task['tess:automated_ingestion'].invoke
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
    Rake::Task['tess:automated_ingestion'].invoke
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
    Rake::Task['tess:automated_ingestion'].invoke

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

  test 'check valid csv files processed' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

    # check success messages
    message = 'Validation passed!'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Sources processed = 3'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'events extracted = 3'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'IngestorEventCsv: events added\[3\] updated\[0\] rejected\[0\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

  test 'check update of existing event' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    event_count = Event.all.size

    # create event
    username = 'Dale'
    user = User.find_by_username(username)
    assert !user.nil?, "Username[#{username}] not found!"

    provider_title = 'Another Portal Provider'
    provider = ContentProvider.find_by_title(provider_title)
    assert !provider.nil?, "Provider title[#{provider_title}] not found!"

    url = 'https://app.com/events/event3.html'
    title = 'Another Event'
    start_datetime = DateTime.now.getutc + 7
    end_datetime = start_datetime + 1
    locked_fields = ['start', 'end', 'timezone', ]

    params = {user: user, content_provider: provider, url: url, title: title, description: 'default description',
              start: start_datetime, end: end_datetime, timezone: 'UTC', contact: 'dummy contact',
              organizer: 'dummy organizer', online: true, city: '', country: '', venue: '',
              eligibility: ['open_to_all',], host_institutions: ['UoLife'], locked_fields: locked_fields }
    event = Event.new(params)
    assert event.save!, 'Event not saved!'
    assert !event.nil?, 'Event not found!'

    assert_equal (event_count + 1), Event.all.size, "Pre-invoke: number of events not matched!"

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

    assert_equal (event_count + 3), Event.all.size, "Post-invoke: number of events not matched!"

    # get event (again)
    events = Event.where(title: title, url: url, content_provider: provider)
    assert !events.nil?, "No events found where title[#{title}] url[#{url}] provider[#{provider.title}]"
    assert !events.first.nil?, "First event not found!"
    updated = events.first

    # check fields of updated event
    assert_equal url, updated.url, "Updated URL not matched!"
    assert_equal title, updated.title, "Updated title not matched!"
    assert_equal provider, updated.content_provider, "Updated provider not matched!"
    assert updated.scraper_record, 'Updated not a scraper record!'
    assert !updated.last_scraped.nil?, 'Updated last scraped is nil!'
    assert_equal 'Event Support', updated.contact, "Updated contact not matched!"
    assert_equal 'Another Content Provider', updated.organizer, "Updated organizer not matched!"
    assert !updated.online, "Updated online not matched!"

    # check locked fields not updated
    assert_equal 'UTC', updated.timezone, "Updated timezone has changed!"
    # TODO: compare datetimes
    # assert_equal start_datetime, updated.start.to_datetime, "Updated start has been changed!"
    # assert_equal end_datetime, updated.end.to_datetime, "Updated end has been changed!"

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