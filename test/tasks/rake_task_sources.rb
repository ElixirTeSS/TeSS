# test/tasks/rake_task_sources.rb

require 'test_helper'

class RakeTasksEventCSVIngestion < ActiveSupport::TestCase

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
    config_file = 'test_ingestion_sources.yml'
    logfile = override_config config_file
    assert_equal 'sources', TeSS::Config.ingestion[:name]

    # enable all sources
    Source.all.each do |source|
      source.enabled = true
      source.save!
    end

    assert_difference 'Event.count', 20 do
      # override time
      freeze_time(stub_time = Time.new(2021)) do ||
        # run task
        Rake::Task['tess:automated_ingestion'].invoke
      end
    end

    # check logfile message
    message = 'Sources processed = 7'
    assert logfile_contains(logfile, message), 'Message found: ' + message

    # check updated source records
    source = get_source_from_url 'https://app.com/materials.csv'
    assert_equal 'csv', source.method
    assert_equal 'material', source.resource_type
    refute source.finished_at.nil?
    assert_stats_equal source, 3,2,2, 0, 1
    refute source.log.nil?
    assert source.log.include? "- Error: Licence must be specified<br />"

    source = get_source_from_url 'https://pawsey.org.au/event/pcon-embracing-new-solutions-for-in-situ-visualisation/?ical=true'
    assert_equal 'ical', source.method
    assert_equal 'event', source.resource_type
    refute source.finished_at.nil?
    assert_stats_equal source, 1,1, 0,1,0
    refute source.log.nil?
    assert source.log.include? "- IngestorEventIcal: events added[0] updated[1] rejected[0]<br />"

    source = get_source_from_url 'https://raw.githubusercontent.com/nci900/NCI_feed_to_DReSA/master/event_NCI.csv'
    assert_equal 'csv', source.method
    assert_equal 'event', source.resource_type
    refute source.finished_at.nil?
    assert_stats_equal source, 14, 14, 14, 0, 0
    refute source.log.nil?
    assert source.log.include? "- IngestorEventCsv: events added[14] updated[0] rejected[0]<br />"
  end

  private

  def get_source_from_url(url)
    sources = Source.where(url: url)
    refute (sources.nil? or sources.empty?), "No sources found for url: #{url}"
    source = sources.first
    assert source.url = url, "Source URL not matched: #{url}"
    return source
  end

  def assert_stats_equal(source, read, written, added, updated, rejected)
    refute source.records_read.nil?, "Read is nil for url: #{source.url}"
    assert_equal read, source.records_read, "Read not matched for url: #{source.url}"
    refute source.records_written.nil?, "Written is nil for url: #{source.url}"
    assert_equal written, source.records_written, "Written not matched for url: #{source.url}"
    refute source.resources_added.nil?, "Added is nil for url: #{source.url}"
    assert_equal added, source.resources_added, "Added not matched for url: #{source.url}"
    refute source.resources_updated.nil?, "Updated is nil for url: #{source.url}"
    assert_equal updated, source.resources_updated, "Updated not matched for url: #{source.url}"
    refute source.resources_rejected.nil?, "Rejected is nil for url: #{source.url}"
    assert_equal rejected, source.resources_rejected, "Rejected not matched for url: #{source.url}"
  end

end