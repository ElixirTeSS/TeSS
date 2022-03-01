# test/tasks/rake_task_event_ingestion.rb

require 'test_helper'

class RakeTasksEventIngestion < ActiveSupport::TestCase

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
    config_file = 'test_ingestion.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # check event doesn't exist
    events = Event.where(title: 'Another Event', url: 'https://app.com/events/event3.html')
    refute events.nil?, "Pre-task: events search error."
    assert_equal 0, events.size, "Pre-task: events search title[Another Event] found something"

    # override time
    freeze_time(stub_time = Time.new(2019)) do ||
      # run task
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check event does exist
    events = Event.where(title: 'Another Event', url: 'https://app.com/events/event3.html')
    refute events.nil?, "Post-task: events search error."
    assert_equal 1, events.size, "Post-task: events search title[Another Event] found nothing"
    event = events.first
    refute event.nil?
    assert_equal 'Another Event', event.title
    assert_equal 'https://app.com/events/event3.html', event.url
    assert_equal 'Another Portal Provider', event.content_provider.title
    assert_equal 'AEST', event.timezone
    assert_equal 'Event Support', event.contact
    assert_equal 'Another Content Provider', event.organizer
    assert_equal 2, event.eligibility.size, "event eligibility size not matched!"
    assert event.eligibility.include?('by_invitation')
    assert_equal 2, event.host_institutions.size
    assert event.host_institutions.include?('UoM')
    refute event.online
    assert_equal 'Melbourne', event.city
    assert_equal 'Australia', event.country
    assert_equal '100 Lygon Street', event.venue

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
    refute user.nil?, "Username[#{username}] not found!"

    provider_title = 'Another Portal Provider'
    provider = ContentProvider.find_by_title(provider_title)
    refute provider.nil?, "Provider title[#{provider_title}] not found!"

    url = 'https://app.com/events/event3.html'
    title = 'Another Event'
    description = 'default description'
    start_datetime = DateTime.new(2022,03,15,13,0,0)
    end_datetime = DateTime.new(2022,03,15,16,0,0)
    locked_fields = ['start', 'timezone', 'description',]

    params = { user: user, content_provider: provider, url: url, title: title, description: description,
               start: start_datetime, end: end_datetime, timezone: 'UTC', contact: 'dummy contact',
               organizer: 'dummy organizer', online: true, city: '', country: '', venue: '',
               eligibility: ['open_to_all',], host_institutions: ['UoLife'], locked_fields: locked_fields }
    event = Event.new(params)
    assert event.save!, 'Event not saved!'
    refute event.nil?, 'Event not found!'
    assert_equal (event_count + 1), Event.all.size, "Pre-invoke: number of events not matched!"

    # override time
    freeze_time(stub_time = Time.new(2022, 02, 01)) do ||
      # run task
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check event count
    assert_equal (event_count + 2), Event.all.size, "Post-invoke: number of events not matched!"

    # get event (again)
    events = Event.where(title: title, url: url, content_provider: provider)
    refute events.nil?, "No events found where title[#{title}] url[#{url}] provider[#{provider.title}]"
    refute events.size > 1, "Duplication events (#{events.size}) found with title[#{title}] url[#{url}] provider[#{provider.title}]"
    refute events.first.nil?, "First event not found!"
    updated = events.first

    # check fields of updated event
    assert_equal url, updated.url, "Updated URL not matched!"
    assert_equal title, updated.title, "Updated title not matched!"
    assert_equal provider, updated.content_provider, "Updated provider not matched!"
    assert updated.scraper_record, 'Updated not a scraper record!'
    refute updated.last_scraped.nil?, 'Updated last scraped is nil!'
    assert_equal 'Event Support', updated.contact, "Updated contact not matched!"
    assert_equal 'Another Content Provider', updated.organizer, "Updated organizer not matched!"
    refute updated.online, "Updated online not matched!"
    assert_equal "20220315T160000".to_datetime, updated.end.to_datetime, "Updated end not matched!"

    # check locked fields not updated
    assert_equal 3, updated.locked_fields.size, "Updated locked_fields count not matched!"
    assert updated.field_locked?(:description), "Updated field (:description) not locked!"
    assert_equal 'UTC', updated.timezone, "Updated timezone has changed!"
    assert_equal description, updated.description, "Updated description has changed!"
    #  compare datetimes
    format = "%Y.%m.%d %H:%M:%s"
    assert_equal start_datetime.strftime(format), updated.start.to_datetime.strftime(format),
                 "Updated start has been changed!"

    # check html -> markdown conversion
    title = 'Awesome Training Day'
    url = 'https://app.com/events/event2.html'
    markdown = "# Awesome Training\n\nThis event already exists. You will learn:\n\n- a thing\n- another thing\n- more stuff\n"
    events = Event.where(title: title, url: url, content_provider: provider)
    event = events.first
    refute event.nil?, "No events found where title[#{title}] url[#{url}] provider[#{provider.title}]"
    assert_equal markdown, event.description, "Event title[#{title}] description not matched!"
  end

end