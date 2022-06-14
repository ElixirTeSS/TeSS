# test/tasks/rake_task_event_ingestion.rb

require 'test_helper'

class RakeTasksEventCSVIngestion < ActiveSupport::TestCase

  setup do
    mock_ingestions
    TeSS::Application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task['tess:automated_ingestion'].reenable
    override_config 'test_ingestion_example.yml'
    assert_equal 'production', TeSS::Config.ingestion[:name]

    # override dictionaries
    TeSS::Config.dictionaries['eligibility'] = 'eligibility_dresa.yml'
    EligibilityDictionary.instance.reload
    TeSS::Config.dictionaries['event_types'] = 'event_types_dresa.yml'
    EventTypeDictionary.instance.reload
    TeSS::Config.dictionaries['licences'] = 'licences_dresa.yml'
    LicenceDictionary.instance.reload
  end

  teardown do
    reset_dictionaries
  end

  test 'check ingestion and validation of events from csv file' do
    # set config file
    config_file = 'test_ingestion_csv.yml'
    logfile = override_config config_file
    assert_equal 'test', TeSS::Config.ingestion[:name]

    # override time
    freeze_time(stub_time = Time.new(2021)) do ||
      # run task
      Rake::Task['tess:automated_ingestion'].invoke
    end

    # check logfile messages
    message = 'IngestorEventCsv: failed with: Illegal quoting'
    refute logfile_contains(logfile, message), 'Message found: ' + message
    message = 'events processed\[14\] added\[14\] updated\[0\] rejected\[0\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    url = 'https://raw.githubusercontent.com/nci900/NCI_feed_to_DReSA/master/event_NCI.csv'
    message = 'resources read\[14\] and written\[14\]'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
    message = 'Scraper.run: finish'
    assert logfile_contains(logfile, message), 'Message not found: ' + message
  end

  test 'check ingestion of event attributes from csv file' do
    # set config file
    override_config 'test_ingestion_csv.yml'
    assert_equal 'test', TeSS::Config.ingestion[:name]

    assert_difference 'Event.count', 14 do
      # override time
      freeze_time(stub_time = Time.new(2021)) do ||
        # run task
        Rake::Task['tess:automated_ingestion'].invoke
      end
    end

    # check timezone transtation - Australia/Sydney -> Sydney
    title = 'Data Manipulation and Visualisation in Python'
    url = 'https://opus.nci.org.au/display/Help/NCI+Training+and+Educational+Events'
    event = get_event title, url
    refute_nil event
    assert_equal 'Sydney',event.timezone

    # check an entry
    title = 'Introduction to Gadi'
    url = 'https://opus.nci.org.au/display/Help/Introduction+to+Gadi'
    description = 'Introduction to Gadi is designed for new users, or users that want a refresher on the basics of Gadi.'
    event = get_event title, url
    refute_nil event

    # check required attributes
    assert_equal title, event.title
    assert_equal url, event.url
    assert_equal description, event.description, "Event title[#{title}] not matched"
    assert_equal DateTime.new(2022, 3, 3, 14, 00, 00), event.start
    assert_equal DateTime.new(2022, 3, 3, 15, 30, 00), event.end
    assert_equal 'Sydney', event.timezone
    assert_equal 'training.nci@anu.edu.au', event.contact
    assert_equal 'NCI', event.organizer
    check_array event.eligibility, ['by_invitation'], ['open_to_all']
    check_array event.host_institutions, ['NCI'], ['Intersect']
    refute event.online

    # check optional attributes
    assert_equal 'NCI, ANU, Ward Road', event.venue
    assert_equal 'Acton', event.city
    assert_equal 'Australia', event.country
    assert_equal '2601', event.postcode
    assert_equal 'To infinity and beyond', event.subtitle
    assert_equal '1.3 hours', event.duration
    assert_equal 'None', event.recognition
    check_array event.event_types, ['webinar', 'hackathon'], ['workshop']
    assert_equal 'charge', event.cost_basis
    assert_equal 'AUD', event.cost_currency
    assert_equal 9.99, event.cost_value
    assert_equal 25, event.capacity
    check_array event.fields, ['BIOINFORMATICS', 'Software Engineering'], ['MATHEMATICS']
    check_array event.keywords, ['Supercomputing','Gadi']
    check_array event.target_audience, ['ecr','researcher', 'phd', 'mbr'], ['ugrad']
    assert_equal 'To provide a basic intro to supercomputing on the **Gadi** system',
                 event.learning_objectives
    assert_equal "To get the most of this session, it would be good to have a basic awareness of:\n\n" +
                   "- Supercomputing\n" + "- Bioinformatics\n" + "- Software Design",
                 event.prerequisites
    assert_equal "There are no technical requirements.",
                 event.tech_requirements
  end

  private

  def check_array(collection, values, exclusions = [])
    assert_not_nil collection
    assert_not_nil values
    assert_kind_of Array, collection
    assert_kind_of Array, values
    assert_equal collection.size, values.size
    values.each { | item | assert_includes collection, item }
    exclusions.each { |item| refute_includes collection, item } unless exclusions.nil?
  end

  def get_event(title, url, provider = nil)
    if provider.nil?
      results = Event.where(title: title, url: url)
    else
      results = Event.where(title: title, url: url, content_provider: provider)
    end
    results.nil? or results.empty? ? nil : results.first
  end

end