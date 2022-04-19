require 'json'
require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
                                                                  SimpleCov::Formatter::HTMLFormatter,
                                                                  SimpleCov::Formatter::LcovFormatter,])
SimpleCov.start 'rails'

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'
require 'minitest/mock'
require 'fakeredis/minitest'

class ActiveSupport::TestCase

  # WARNING: Do not be tempted to include Devise TestHelpers here (e.g. include Devise::TestHelpers)
  # It must be included in each controller it is needed in or unit tests will break.

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # reset dictionaries to their default values
  def reset_dictionaries
    dictionaries = TeSS::Config.dictionaries
    # reset default dictionary files
    dictionaries['difficulty'] = DifficultyDictionary::DEFAULT_FILE
    dictionaries['eligibility'] = EligibilityDictionary::DEFAULT_FILE
    dictionaries['event_types'] = EventTypeDictionary::DEFAULT_FILE
    dictionaries['cost_basis'] = CostBasisDictionary::DEFAULT_FILE
    dictionaries['material_type'] = MaterialTypeDictionary::DEFAULT_FILE
    dictionaries['material_status'] = MaterialStatusDictionary::DEFAULT_FILE
    dictionaries['target_audience'] = TargetAudienceDictionary::DEFAULT_FILE
    dictionaries['trainer_experience'] = TrainerExperienceDictionary::DEFAULT_FILE
    DifficultyDictionary.instance.reload
    EligibilityDictionary.instance.reload
    EventTypeDictionary.instance.reload
    CostBasisDictionary.instance.reload
    MaterialTypeDictionary.instance.reload
    MaterialStatusDictionary.instance.reload
    TargetAudienceDictionary.instance.reload
    TrainerExperienceDictionary.instance.reload
  end

  # override Time.now for testing calendars, etc.
  def freeze_time(fixed_time=Time.now, &block)
    Time.stub(:now, fixed_time) do
      fixed_time.stub(:iso8601, fixed_time) do
        block.call
      end
    end
  end

  WebMock.disable_net_connect!(allow_localhost: true, allow: 'api.codacy.com')

  # Mock remote images so paperclip doesn't break:
  def mock_images
    WebMock.stub_request(:any, /http\:\/\/example\.com\/(.+)\.png/).to_return(
      status: 200, body: File.read(File.join(Rails.root, 'test/fixtures/files/image.png')),
      headers: { content_type: 'image/png' }
    )

    WebMock.stub_request(:any, "http://image.host/another_image.png").to_return(
      status: 200, body: File.read(File.join(Rails.root, 'test/fixtures/files/another_image.png')),
      headers: { content_type: 'image/png' }
    )

    WebMock.stub_request(:any, "http://malicious.host/image.png").to_return(
      status: 200, body: File.read(File.join(Rails.root, 'test/fixtures/files/bad.js')), headers: { content_type: 'image/png' }
    )

    WebMock.stub_request(:any, "http://text.host/text.txt").to_return(
      status: 200, body: File.read(File.join(Rails.root, 'test/fixtures/files/text.txt')), headers: { content_type: 'text/plain' }
    )

    WebMock.stub_request(:any, "http://404.host/image.png").to_return(status: 404)

    WebMock.stub_request(:get, "https://bio.tools/api/tool?q=Training%20Material%20Example").
      with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Ruby' }).
      to_return(:status => 200, :body => "", :headers => {})

    WebMock.stub_request(:get, "https://bio.tools/api/tool?q=Material%20with%20suggestions").
      with(:headers => { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Ruby' }).
      to_return(:status => 200, :body => "", :headers => {})

  end

  def mock_orcids
    WebMock.stub_request(:get, 'https://orcid.org/').to_return(status: 200)
    WebMock.stub_request(:get, 'https://orcid.org/0000-0001-1234-0000').to_return(status: 200)
    WebMock.stub_request(:get, 'https://orcid.org/0000-0001-1234-9999').to_return(status: 404)
    WebMock.stub_request(:get, 'https://orcid.org/000-0002-1825-0097x').to_return(status: 404)
  end

  def mock_ingestions
    events_file = File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'events.csv'))
    events_nci_file = File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'events_NCI.csv'))
    materials_file = File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'materials.csv'))
    zenodo_ardc_body = File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'zenodo_ardc.json'))
    zenodo_ardc_2_body = File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'zenodo_ardc_2.json'))
    zenodo_ardc_3_body = File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'zenodo_ardc_3.json'))
    zenodo_abt_body = File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'zenodo_abt.json'))
    elixir_ausbioc_body = File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'response_1642570417380.json'))
    test_sitemap = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'Test-Sitemap.xml']))
    pawsey_ical_1 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'icalendar', 'ask-me-anything-porous-media-visualisation-and-lbpm.ics']))
    pawsey_ical_2 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'icalendar', 'experience-with-porting-and-scaling-codes-on-amd-gpus.ics']))
    pawsey_ical_3 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'icalendar', 'nvidia-cuquantum-session.ics']))
    pawsey_ical_4 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'icalendar', 'overview-of-high-performance-computing-resources-at-olcf.ics']))
    pawsey_ical_5 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'icalendar', 'pacer-seminar-computational-fluid-dynamics.ics']))
    pawsey_ical_6 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'icalendar', 'pacer-seminar-radio-astronomy.ics']))
    pawsey_ical_7 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'icalendar', 'pawsey-intern-showcase-2022.ics']))
    pawsey_ical_8 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'icalendar', 'pcon-embracing-new-solutions-for-in-situ-visualisation.ics']))
    pawsey_ical_9 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'icalendar', 'pawsey-intern-showcase-2021.ics']))
    pawsey_ical_a = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'icalendar', 'pawsey-supercomputing-centre-5cd096b58d0.ics']))

    # eventbrite object files
    eventbrite_ardc_body = File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'eventbrite', 'eventbrite_ardc.json'))
    eventbrite_ardc_2_body = File.read(File.join(Rails.root, 'test', 'fixtures', 'files', 'eventbrite', 'eventbrite_ardc_2.json'))
    eventbrite_organizer_14317910674 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'eventbrite', 'organizer_14317910674.json']))
    eventbrite_organizer_8082048069 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'eventbrite', 'organizer_8082048069.json']))
    eventbrite_venue_88342919 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'eventbrite', 'venue_88342919.json']))
    eventbrite_categories = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'eventbrite', 'categories.json']))
    eventbrite_categories_101 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'eventbrite', 'categories_101.json']))
    eventbrite_categories_102 = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'eventbrite', 'categories_102.json']))
    eventbrite_formats = File.read(File.join(Rails.root, ['test', 'fixtures', 'files', 'eventbrite', 'formats.json']))

    # 200 - success
    WebMock.stub_request(:get, 'https://app.com/events.csv').
      to_return(:status => 200, :headers => {}, :body => events_file)
    WebMock.stub_request(:get, 'https://raw.githubusercontent.com/nci900/NCI_feed_to_DReSA/master/event_NCI.csv').
      to_return(:status => 200, :headers => {}, :body => events_nci_file)
    WebMock.stub_request(:get, 'https://app.com/materials.csv').
      to_return(:status => 200, :headers => {}, :body => materials_file)
    WebMock.stub_request(:get, 'https://app.com/events/event3.html').
      to_return(:status => 200)
    WebMock.stub_request(:get, 'https://zenodo.org/api/records/?communities=ardc').
      to_return(status: 200, headers: {}, body: zenodo_ardc_body)
    WebMock.stub_request(:get, 'https://zenodo.org/api/records/?sort=mostrecent&communities=ardc&page=2&size=10').
      to_return(status: 200, headers: {}, body: zenodo_ardc_2_body)
    WebMock.stub_request(:get, 'https://zenodo.org/api/records/?communities=ardc-again').
      to_return(status: 200, headers: {}, body: zenodo_ardc_3_body)
    WebMock.stub_request(:get, 'https://zenodo.org/api/records/?communities=australianbiocommons-training').
      to_return(status: 200, headers: {}, body: zenodo_abt_body)
    WebMock.stub_request(:get, 'https://tess.elixir-europe.org/events?include_expired=false&content_provider[]=Australian BioCommons').
      to_return(status: 200, headers: {}, body: elixir_ausbioc_body)
    WebMock.stub_request(:get, 'https://app.com/events/sitemap.xml').
      to_return(status: 200, headers: {}, body: test_sitemap)

    WebMock.stub_request(:get, 'https://pawsey.org.au/event/ask-me-anything-porous-media-visualisation-and-lbpm/?ical=true').
      to_return(status: 200, headers: {}, body: pawsey_ical_1)
    WebMock.stub_request(:get, 'https://pawsey.org.au/event/experience-with-porting-and-scaling-codes-on-amd-gpus/?ical=true').
      to_return(status: 200, headers: {}, body: pawsey_ical_2)
    WebMock.stub_request(:get, 'https://pawsey.org.au/event/nvidia-cuquantum-session/?ical=true').
      to_return(status: 200, headers: {}, body: pawsey_ical_3)
    WebMock.stub_request(:get, 'https://pawsey.org.au/event/overview-of-high-performance-computing-resources-at-olcf/?ical=true').
      to_return(status: 200, headers: {}, body: pawsey_ical_4)
    WebMock.stub_request(:get, 'https://pawsey.org.au/event/pacer-seminar-computational-fluid-dynamics/?ical=true').
      to_return(status: 200, headers: {}, body: pawsey_ical_5)
    WebMock.stub_request(:get, 'https://pawsey.org.au/event/pacer-seminar-radio-astronomy/?ical=true').
      to_return(status: 200, headers: {}, body: pawsey_ical_6)
    WebMock.stub_request(:get, 'https://pawsey.org.au/event/pawsey-intern-showcase-2022/?ical=true').
      to_return(status: 200, headers: {}, body: pawsey_ical_7)
    WebMock.stub_request(:get, 'https://pawsey.org.au/event/pcon-embracing-new-solutions-for-in-situ-visualisation/?ical=true').
      to_return(status: 200, headers: {}, body: pawsey_ical_8)
    WebMock.stub_request(:get, 'https://pawsey.org.au/event/pawsey-intern-showcase-2021/?ical=true').
      to_return(status: 200, headers: {}, body: pawsey_ical_9)
    WebMock.stub_request(:get, 'https://pawsey.org.au/event/eoi-1-day-introduction-to-amd-gpus-amd-instinct-architecture-and-rocm/?ical=true').
      to_return(status: 200, headers: {}, body: pawsey_ical_a)


    # eventbrite objects
    WebMock.stub_request(:get,'https://www.eventbriteapi.com/v3/organizations/34338661734/events/?token=YXAKB2UNBVO7FV5SJHQA').
      to_return(status: 200, headers: {}, body: eventbrite_ardc_body)
    WebMock.stub_request(:get,'https://www.eventbriteapi.com/v3/organizations/34338661734/events/?page=2&token=YXAKB2UNBVO7FV5SJHQA').
      to_return(status: 200, headers: {}, body: eventbrite_ardc_2_body)
    WebMock.stub_request(:get,'https://www.eventbriteapi.com/v3/organizations/34338661734/events/?status=live&token=YXAKB2UNBVO7FV5SJHQA').
      to_return(status: 200, headers: {}, body: eventbrite_ardc_2_body)
    WebMock.stub_request(:get, 'https://www.eventbriteapi.com/v3/organizers/14317910674/?token=YXAKB2UNBVO7FV5SJHQA').
      to_return(status: 200, headers: {}, body: eventbrite_organizer_14317910674 )
    WebMock.stub_request(:get, 'https://www.eventbriteapi.com/v3/organizers/8082048069/?token=YXAKB2UNBVO7FV5SJHQA').
      to_return(status: 200, headers: {}, body: eventbrite_organizer_8082048069 )
    WebMock.stub_request(:get, 'https://www.eventbriteapi.com/v3/venues/88342919/?token=YXAKB2UNBVO7FV5SJHQA').
      to_return(status: 200, headers: {}, body: eventbrite_venue_88342919 )
    WebMock.stub_request(:get, 'https://www.eventbriteapi.com/v3/categories/?token=YXAKB2UNBVO7FV5SJHQA').
      to_return(status: 200, headers: {}, body: eventbrite_categories )
    WebMock.stub_request(:get, 'https://www.eventbriteapi.com/v3/categories/101/?token=YXAKB2UNBVO7FV5SJHQA').
      to_return(status: 200, headers: {}, body: eventbrite_categories_101 )
    WebMock.stub_request(:get, 'https://www.eventbriteapi.com/v3/categories/102/?token=YXAKB2UNBVO7FV5SJHQA').
      to_return(status: 200, headers: {}, body: eventbrite_categories_102 )
    WebMock.stub_request(:get, 'https://www.eventbriteapi.com/v3/formats/?token=YXAKB2UNBVO7FV5SJHQA').
      to_return(status: 200, headers: {}, body: eventbrite_formats )

    # 404 - not found
    WebMock.stub_request(:get, 'https://dummy.com').to_return(:status => 404)
    WebMock.stub_request(:get, 'https://dummy.com/events.csv').to_return(:status => 404)
    WebMock.stub_request(:get, 'https://app.com/materials/material3.html').to_return(:status => 200)
    WebMock.stub_request(:get, 'https://dummy.com/materials.csv').to_return(:status => 404)
    WebMock.stub_request(:get, 'https://zenodo.org/api/records/?sort=mostrecent&ommunities=australianbiocommons-training&page=2&size=10').
      to_return(status: 404)
    WebMock.stub_request(:get, 'https://zenodo.org/api/records/?communities=dummy').to_return(:status => 404)
    WebMock.stub_request(:get, 'https://missing.org/sitemap.xml').to_return(:status => 404)
    WebMock.stub_request(:get, 'https://pawsey.org.au/events/?ical=true').to_return(:status => 404)
    WebMock.stub_request(:get, 'https://www.eventbriteapi.com/v3/organizations/34338661734').to_return(:status => 404)
  end

  def mock_biotools
    biotools_file = File.read("#{Rails.root}/test/fixtures/files/annotation.json")
    WebMock.stub_request(:get, /data.bioontology.org/).
      to_return(:status => 200, :headers => {}, :body => biotools_file)
  end

  def mock_nominatim
    nominatim_file = File.read(File.join(Rails.root, ['test', 'fixtures','files', 'nominatim.json'] ))
    kensington_file = File.read(File.join(Rails.root,['test', 'fixtures', 'files', 'geocode_kensington.json'] ))

    WebMock.stub_request(:get, /nominatim.openstreetmap.org/).
      to_return(:status => 200, :headers => {}, :body => nominatim_file)

    # geocoder overrides
    Geocoder.configure(lookup: :test, ip_lookup: :test)
    Geocoder::Lookup::Test.add_stub( "1 Bryce Avenue, Kensington, Western Australia, 6151, Australia", JSON.parse(kensington_file) )
    Geocoder::Lookup::Test.add_stub( "Pawsey Supercomputing Centre, 1 Bryce Avenue, Kensington, Western Australia, 6151, Australia", [] )
    Geocoder::Lookup::Test.add_stub( "Australia", [{ "address"=>{ "country"=>"Australia", "country_code"=>"au"} }] )
  end

  # helper methods for ingestion tests
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

  # This should probably live somewhere else
  class MockSearchResults < Array
    def initialize(collection)
      replace(Array(collection))
    end

    def total_count
      count
    end

    def total_pages
      2
    end

    def current_page
      1
    end

    def next_page
      2
    end

    def previous_page
      nil
    end
  end

  class MockSearch
    def initialize(collection)
      @collection = Array(collection)
    end

    def results
      MockSearchResults.new(@collection)
    end

    def facets
      @facets ||= mock_facets
    end

    def facet(field_name)
      facets.detect { |f| f.field_name == field_name }
    end

    def total
      results.total_count
    end

    private

    def mock_facets
      if @collection.any?
        c = @collection.first.class
        f = c.facet_fields.map do |ff|
          { field_name: ff.to_sym, rows: (1 + rand(4)).times.map { { value: 'Fish', count: (1 + rand(4)) } } }
        end
        JSON.parse(f.to_json, object_class: OpenStruct)
      else
        {}
      end
    end
  end
end

# Minitest's `stub` method but ignores any blocks
class Object

  def blockless_stub name, val_or_callable, *block_args
    new_name = "__minitest_stub__#{name}"

    metaclass =

      class << self
        self;
      end

    if respond_to? name and not methods.map(&:to_s).include? name.to_s then
      metaclass.send :define_method, name do |*args|
        super(*args)
      end
    end

    metaclass.send :alias_method, new_name, name

    metaclass.send :define_method, name do |*args|
      ret = if val_or_callable.respond_to? :call then
              val_or_callable.call(*args)
            else
              val_or_callable
            end

      ret
    end

    yield self
  ensure
    metaclass.send :undef_method, name
    metaclass.send :alias_method, name, new_name
    metaclass.send :undef_method, new_name
  end
end
