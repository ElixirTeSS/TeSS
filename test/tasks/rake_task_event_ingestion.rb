# test/tasks/rake_task_event_ingestion.rb

require 'test_helper'

class RakeTasksEventIngestion < ActiveSupport::TestCase

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


  test 'check ingestion and validation of events from csv file' do
    # set config file
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]
    material_count = Material.all.size

    # run task
    # expect addited[1] updated[1] rejected[1]
    Rake::Task['tess:automated_ingestion'].invoke

    # check logfile messages
    message = 'IngestorEventCsv: events extracted = 3'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'IngestorEventCsv: events added\[3\] updated\[0\] rejected\[0\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Source URL\[https://app.com/events.csv\] resources read\[3\] and written\[3\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

  test 'check ingestion of new and updated events from csv file' do
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
    description = 'default description'
    start_datetime = DateTime.now.getutc + 7
    end_datetime = start_datetime + 1
    locked_fields = ['start', 'timezone', 'description',]

    params = { user: user, content_provider: provider, url: url, title: title, description: description,
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
    assert_equal "20220315T160000".to_datetime, updated.end.to_datetime, "Updated end not matched!"

    # check locked fields not updated
    assert_equal 3, updated.locked_fields.size, "Updated locked_fields count not matched!"
    assert updated.field_locked?(:description), "Updated field (:description) not locked!"
    assert_equal 'UTC', updated.timezone, "Updated timezone has changed!"
    assert_equal description, updated.description, "Updated description has changed!"
    # TODO: compare datetimes
    format = "%Y.%m.%d %H:%M:%s"
    assert_equal start_datetime.strftime(format), updated.start.to_datetime.strftime(format),
                 "Updated start has been changed!"

  end

end