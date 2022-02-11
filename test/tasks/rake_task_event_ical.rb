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
    assert_equal 21, event_count, 'Pre-task: event count not matched.'

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
    check_logfile logfile, 'Event title\[PaCER Seminar: Radio astronomy\] error: event start time has passed'
    # TODO: check added
    event = check_event_exists 'Ask Me Anything: Porous media visualisation and LBPM',
                                'https://pawsey.org.au/event/ask-me-anything-porous-media-visualisation-and-lbpm/'
    assert event.online, "event title[#{event.title}] online not matched"
    assert (!event.keywords.nil? and event.keywords.size == 2), "event title[#{event.title}] keywords.size not matched"
    puts "event.keywords: #{event.keywords.inspect}"
    assert event.keywords.include?("AMA"), "event title[#{event.title}] keyword[AMA] not found"
    assert event.keywords.include?('Visualisation'), "event title[#{event.title}] keyword[Visualisation] not found"
    desc = "If you are working on Digital Rock Physics and interested in fluid flow behaviour in Porous Media\, " +
      "this AMA is for you.  \nPlease join us to discuss Lattice Boltzmann Method for Porous Media (LBPM) " +
      "and the opportunities for Pawsey researchers.  \nLBPM is one of the most complete derivatives of " +
      "the Lattice Boltzmann Method (LBM) focusing on porous media providing computational as well as " +
      "visualisation modules at a micro-scale. LBM is a well-known simulation tool in CFD\, producing highly " +
      "reliable results.   \nLBPM:  \n\nfocuses on porous media at micro–scale \nis accurate  \n" +
      "is scalable \nhas features integrated with upscaling tools/techniques in high demand in the oil and " +
      "gas industry \nis capable of running simulation in CSG/CBM as extremely " +
      "heterogeneous unconventional reservoirs rocks\nis free and open-source \n\n Is LBPM of interest " +
      "to the research community working at scale? Join the discussion at this AMA\, and send your questions " +
      "in advance via the registration form.   \n More information about LBPM: https://github.com/OPM/LBPM " +
      " \nRegister here to join this AMA.\nBelow is a sample visualisation derived from open-source data " +
      "\n\nhttps://pawsey.org.au/wp-content/uploads/2021/06/movie.mp4\n"
    assert_equal desc, event.description, "event title[#{event.title}] description not matched"

    # TODO: check updated

    # TODO: check totals
    check_logfile logfile, "IngestorEventIcal: events added[#{added}] updated[#{updated}] rejected[#{rejected}]"
    assert_equal event_count + added, Event.all.size, 'Post-task: event count not matched'

  end

  private

  def check_event_exists(title, url)
    events = Event.where(title: title, url: url)
    assert (!events.nil? and events.size == 1), "event title[#{title}] not found"
    return events.first
  end

  def check_logfile(logfile, message)
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

end
