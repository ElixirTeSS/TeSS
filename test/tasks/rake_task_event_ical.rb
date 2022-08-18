# test/tasks/rake_task_event_rest.rb

require 'test_helper'

class RakeTaskEventIcal < ActiveSupport::TestCase

  setup do
    mock_ingestions
    mock_nominatim
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

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

    # post task validation
    # check logfile messages for source #1
    check_logfile logfile, 'Validation error: URL not accessible: https://missing.org/sitemap.xml'
  end

  test 'invalid source definition' do
    # set config file
    config_file = 'test_ingestion_ical.yml'
    logfile = override_config config_file
    assert_equal 'ical_event', TeSS::Config.ingestion[:name]

    # run task
    Rake::Task['tess:automated_ingestion'].invoke

    # post task validation
    # check logfile messages for source #2
    message = 'Ingestor not yet implemented for method\[ical\] and resource\[material\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

  test 'ingest valid sitemap' do
    # set config file
    config_file = 'test_ingestion_ical.yml'
    logfile = override_config config_file
    assert_equal 'ical_event', TeSS::Config.ingestion[:name]
    event_count = Event.all.size
    assert_equal 23, event_count, 'Pre-task: event count not matched.'
    provider = content_providers :another_portal_provider
    refute provider.nil?, "Content Provider not found."
    Time.zone = 'Australia/Perth'

    # check two events to be updated
    name = 'ical_event_1'
    event = events(:ical_event_1)
    refute event.nil?, "event[#{name}] not found"
    refute event.online, "event[#{name}] online not matched"
    assert_equal "Another Portal Provider", event.content_provider.title,
                 "event[#{name}] content provider not matched"

    name = 'ical_event_2'
    refute events(name).nil?, "fixture[#{name}] not found"
    title = 'PaCER Seminar: Computational Fluid Dynamics'
    url = 'https://pawsey.org.au/event/pacer-seminar-computational-fluid-dynamics/'
    event = check_event_exists title, url
    refute event.nil?, "event title[#{title}] not found"
    refute event.online, "event title[#{title}] online not matched"
    assert_equal "Another Portal Provider", event.content_provider.title,
                 "event title[#{title}] content provider not matched"
    dtstart = Time.zone.parse '2022-06-15 10:00:00'

    # check matches
    matches = Event.where(title: title, url: url, start: dtstart,
                          content_provider: provider)
    refute matches.nil?, "matches is nil"
    assert_equal 1, matches.size, "matches size = #{matches.size}"

    # override time
    freeze_time(stub_time = Time.new(2019)) do ||
      # run task
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # post task validation
    added = 4; updated = 2; rejected = 2;

    # check individual events
    # check not found
    check_logfile logfile, 'process file url\[https://pawsey.org.au/events/\?ical=true\] failed with: 404'

    # check rejected
    check_logfile logfile, 'Event title\[NVIDIA cuQuantum Session\] error: City can\'t be blank'
    check_logfile logfile, 'Event title\[PaCER Seminar: Radio astronomy\] error: event has expired'

    # check added
    title = 'Ask Me Anything: Porous media visualisation and LBPM'
    event = check_event_exists title, 'https://pawsey.org.au/event/ask-me-anything-porous-media-visualisation-and-lbpm/'
    assert event.online, "event title[#{event.title}] online not matched"
    assert (!event.keywords.nil? and event.keywords.size == 2), "event title[#{event.title}] keywords.size not matched"
    assert event.keywords.include?("AMA"), "event title[#{event.title}] keyword[AMA] not found"
    assert event.keywords.include?('Visualisation'), "event title[#{event.title}] keyword[Visualisation] not found"

    title = 'Pawsey Intern Showcase 2022'
    event = check_event_exists title, 'https://pawsey.org.au/event/pawsey-intern-showcase-2022/'
    desc = "The Pawsey Supercomputing Research Centre takes prides in its Summer Internship Program – " +
      "working in partnership with bright students on challenging and interesting projects. \nLike last year, " +
      "this year’s Intern cohort more than doubled in size, now at 47 Interns, working with dozens of committed PIs " +
      "and supervisors around the country. The Intern Mentor Program also continues to grow and change, as does the " +
      "range of trainings we immerse students in during Week 1 of the Program (and throughout)."
    assert_equal desc.size, event.description.size, "event title[#{event.title}] description.size not matched"
    assert_equal desc, event.description, "event title[#{event.title}] description not matched"
    assert_equal Time.zone.name, event.timezone.to_s, "event title[#{event.title}] timezone not matched"
    dtstart = Time.zone.parse('2022-02-11 09:45:00')
    dtend = Time.zone.parse('2022-02-11 12:50:00')
    assert_equal dtstart, event.start, "event title[#{event.title}] start not matched"
    assert_equal dtend, event.end, "event title[#{event.title}] end not matched"

    title = 'P\'Con - Experience with porting and scaling codes on AMD GPUs'
    event = check_event_exists title, 'https://pawsey.org.au/event/experience-with-porting-and-scaling-codes-on-amd-gpus/'
    assert event.online, "event title[#{title}] online not matched"

    title = 'Overview of High Performance Computing Resources at OLCF'
    event = check_event_exists title, 'https://pawsey.org.au/event/overview-of-high-performance-computing-resources-at-olcf/'
    refute event.online, "event title[#{title}] online not matched"
    location = 'Pawsey Supercomputing Centre, 1 Bryce Avenue, Kensington, Western Australia, 6151, Australia'
    assert_equal location, event.venue, "event title[#{title}] venue not matched"
    assert_equal 'Kensington', event.city, "event title[#{title}] city not matched"
    assert_equal '6151', event.postcode, "event title[#{title}] postcode not matched"
    assert_equal 'Australia', event.country, "event title[#{title}] country not matched"

    # TODO: check updated
    title = 'PaCER Seminar: Computational Fluid Dynamics'
    event = check_event_exists title, 'https://pawsey.org.au/event/pacer-seminar-computational-fluid-dynamics/'
    assert_equal Time.zone.parse('2022-06-15 11:00:00'), event.end, "event title[#{event.title}] updated end not matched"
    assert event.description != 'MyText', "event title[#{event.title}] description not updated"
    assert event.description.size > 100, "event title[#{event.title}] description too short"
    assert event.online, "event title[#{event.title}] online not matched"
    assert_equal 2, event.keywords.size, "event title[#{event.title}] keywords size not matched"
    ['Supercomputing', 'Seminar'].each do |keyword|
      assert event.keywords.include?(keyword), "event title[#{event.title}] keyword[#{keyword}] not found"
    end
    assert_equal 'Online, Virtual, Australia', event.venue, "event title[#{event.title}] venue not matched"
    assert event.city.nil?, "event title[#{event.title}] city not matched"
    assert event.postcode.nil?, "event title[#{event.title}] postcode not matched"
    assert event.country.nil?, "event title[#{event.title}] country not matched"

    title = "P'Con - Embracing new solutions for in-situ visualisation"
    event = check_event_exists title, 'https://pawsey.org.au/event/pcon-embracing-new-solutions-for-in-situ-visualisation/'
    assert event.online, "event title[#{event.title}] online not matched"
    assert_equal 3, event.keywords.size, "event title[#{event.title}] keywords size not matched"
    ['Supercomputing', 'Conference', 'Visualisation'].each do |keyword|
      assert event.keywords.include?(keyword), "event title[#{event.title}] keyword[#{keyword}] not found"
    end
    assert_equal 'Online, Virtual, Australia', event.venue, "event title[#{event.title}] venue not matched"
    assert event.postcode.nil?, "event title[#{event.title}] postcode not matched"
    assert event.city.nil?, "event title[#{event.title}] city not matched"
    assert event.country.nil?, "event title[#{event.title}] country not matched"

    # TODO: check totals
    check_logfile logfile, 'IngestorEventIcal: events added\[4\] updated\[2\] rejected\[2\]'
    assert_equal event_count + added, Event.all.size, 'Post-task: event count not matched'

  end

  test 'check single ical sources' do
    # set config file
    config_file = 'test_ingestion_ical_2.yml'
    logfile = override_config config_file
    assert_equal 'ical_events_2', TeSS::Config.ingestion[:name]
    assert_equal 23, Event.all.size, 'Pre-task: event count not matched.'
    provider = content_providers :another_portal_provider
    refute provider.nil?, "Content Provider not found."
    Time.zone = 'Australia/Perth'

    # override time
    assert_no_difference 'Event.count'do
      freeze_time(stub_time = Time.new(2019)) do ||
        # run task
        Rake::Task['tess:automated_ingestion'].invoke
      end

      # get updated
      title = 'P\'Con - Embracing new solutions for in-situ visualisation'
      url = 'https://pawsey.org.au/event/pcon-embracing-new-solutions-for-in-situ-visualisation/'
      event = check_event_exists title, url
      assert_equal 3, event.keywords.size
      ['Supercomputing', 'Conference', 'Visualisation'].each do |keyword|
        assert event.keywords.include?(keyword), "event title[#{event.title}] keyword[#{keyword}] not found"
      end
    end

    # check logfile
    assert check_logfile logfile, 'Event failed validation: Pawsey Intern Showcase 2021'
    assert check_logfile logfile, 'Error: Description can\'t be blank'
    assert check_logfile logfile, 'events processed\[1\] added\[0\] updated\[0\] rejected\[1\]'
    assert check_logfile logfile, 'events processed\[1\] added\[0\] updated\[1\] rejected\[0\]'
  end

  private

  def check_event_exists(title, url)
    events = Event.where(title: title, url: url)
    assert (!events.nil? and events.size > 0), "event title[#{title}] not found"
    assert events.size < 2, "event[#{title}] duplicates found = #{events.size}"
    return events.first
  end

  def check_logfile(logfile, message)
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

end
