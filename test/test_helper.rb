require 'json'
require 'simplecov'
require 'simplecov-lcov'

SimpleCov::Formatter::LcovFormatter.config.report_with_single_file = true

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::LcovFormatter
])

SimpleCov.start do
  add_filter '.gems'
  add_filter 'pkg'
  add_filter 'spec'
  add_filter 'vendor'
end

ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'webmock/minitest'
require 'minitest/mock'
require 'minitest/reporters'
require 'vcr'
require_relative './schema_helper'

WebMock.disable_net_connect!(allow_localhost: true, allow: 'api.codacy.com')
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(
  fast_fail: true, color: true, detailed_skip: false, slow_count: 10)] unless ENV['RM_INFO']

VCR.configure do |config|
  config.cassette_library_dir = 'test/vcr_cassettes'
  config.hook_into :webmock
  config.allow_http_connections_when_no_cassette = true
end

class ActiveSupport::TestCase
  include SchemaHelper

  setup do
    redis = Redis.new(url: TeSS::Config.redis_url)
    redis.flushdb
  end

  teardown do
    User.current_user = nil
  end

  # WARNING: Do not be tempted to include Devise TestHelpers here (e.g. include Devise::TestHelpers)
  # It must be included in each controller it is needed in or unit tests will break.

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...

  # Temporarily change TeSS config for the duration of the block
  def with_settings(settings, overwrite = false, &block)
    orig_config = {}
    settings.each do |k, v|
      orig_config[k] = TeSS::Config[k]
      if !overwrite && TeSS::Config[k].is_a?(Hash) && v.is_a?(Hash)
        TeSS::Config[k] = v.with_indifferent_access.reverse_merge!(TeSS::Config[k])
      else
        TeSS::Config[k] = v
      end
    end
    block.call
  ensure
    orig_config.each { |k, v| TeSS::Config[k] = v }
  end

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

  class DresaEventTypeDictionary < ::EventTypeDictionary
    def dictionary_filepath
      Rails.root.join('config', 'dictionaries', 'event_types_dresa.yml')
    end
  end

  class DresaEligibilityDictionary < ::EligibilityDictionary
    def dictionary_filepath
      Rails.root.join('config', 'dictionaries', 'eligibility_dresa.yml')
    end
  end

  class DresaLicenceDictionary < ::LicenceDictionary
    def dictionary_filepath
      Rails.root.join('config', 'dictionaries', 'licences_dresa.yml')
    end
  end

  def self.dresa_dictionaries
    # Cache to prevent loading for every test
    @dresa_dictionaries ||= {
      event_types: DresaEventTypeDictionary.instance,
      eligibility: DresaEligibilityDictionary.instance,
      licenses: DresaLicenceDictionary.instance
    }
  end

  def with_dresa_dictionaries(&block)
    self.class.dresa_dictionaries # Ensure dictionaries are loaded dictionaries before stubbing to prevent infinite loop
    EventTypeDictionary.stub(:instance, -> { self.class.dresa_dictionaries[:event_types] }) do
      EligibilityDictionary.stub(:instance, -> { self.class.dresa_dictionaries[:eligibility] }) do
        LicenceDictionary.stub(:instance, -> { self.class.dresa_dictionaries[:licenses] }) do
          block.call
        end
      end
    end
  end

  # override Time.now for testing calendars, etc.
  def freeze_time(time_or_year = Time.now, &block)
    # 3rd of Jan in given year (stops year/month underflowing if timezone changes)
    time_or_year = Time.new(time_or_year, 1, 3).utc if time_or_year.is_a?(Integer)
    Time.stub(:now, time_or_year) do
      time_or_year.stub(:iso8601, time_or_year) do
        block.call
      end
    end
  end

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
    [{ url: 'https://app.com/events.csv', filename: 'events.csv' },
     { url: 'https://raw.githubusercontent.com/nci900/NCI_feed_to_DReSA/master/event_NCI.csv', filename: 'events_NCI.csv' },
     { url: 'https://app.com/materials.csv', filename: 'materials.csv' },
     { url: 'https://app.com/events/event3.html' },
     { url: 'https://zenodo.org/api/records/?communities=ardc', filename: 'zenodo_ardc.json' },
     { url: 'https://zenodo.org/api/records?communities=ardc&page=2&size=25&sort=newest', filename: 'zenodo_ardc_2.json' },
     { url: 'https://zenodo.org/api/records/?communities=ardc-again', filename: 'zenodo_ardc_3.json' },
     { url: 'https://zenodo.org/api/records/?communities=australianbiocommons-training', filename: 'zenodo_abt.json' },
     { url: 'https://tess.elixir-europe.org/events?include_expired=false&content_provider[]=Australian BioCommons', filename: 'response_1642570417380.json' },
     { url: 'https://app.com/events/sitemap.xml', filename: 'Test-Sitemap.xml' },
     { url: 'https://pawsey.org.au/event/ask-me-anything-porous-media-visualisation-and-lbpm/?ical=true', filename: 'icalendar/ask-me-anything-porous-media-visualisation-and-lbpm.ics' },
     { url: 'https://pawsey.org.au/event/experience-with-porting-and-scaling-codes-on-amd-gpus/?ical=true', filename: 'icalendar/experience-with-porting-and-scaling-codes-on-amd-gpus.ics' },
     { url: 'https://pawsey.org.au/event/nvidia-cuquantum-session/?ical=true', filename: 'icalendar/nvidia-cuquantum-session.ics' },
     { url: 'https://pawsey.org.au/event/overview-of-high-performance-computing-resources-at-olcf/?ical=true', filename: 'icalendar/overview-of-high-performance-computing-resources-at-olcf.ics' },
     { url: 'https://pawsey.org.au/event/pacer-seminar-computational-fluid-dynamics/?ical=true', filename: 'icalendar/pacer-seminar-computational-fluid-dynamics.ics' },
     { url: 'https://pawsey.org.au/event/pacer-seminar-radio-astronomy/?ical=true', filename: 'icalendar/pacer-seminar-radio-astronomy.ics' },
     { url: 'https://pawsey.org.au/event/pawsey-intern-showcase-2022/?ical=true', filename: 'icalendar/pawsey-intern-showcase-2022.ics' },
     { url: 'https://pawsey.org.au/event/pcon-embracing-new-solutions-for-in-situ-visualisation/?ical=true', filename: 'icalendar/pcon-embracing-new-solutions-for-in-situ-visualisation.ics' },
     { url: 'https://pawsey.org.au/event/pawsey-intern-showcase-2021/?ical=true', filename: 'icalendar/pawsey-intern-showcase-2021.ics' },
     { url: 'https://pawsey.org.au/event/eoi-1-day-introduction-to-amd-gpus-amd-instinct-architecture-and-rocm/?ical=true', filename: 'icalendar/pawsey-supercomputing-centre-5cd096b58d0.ics' },
     { url: 'https://www.eventbriteapi.com/v3/organizations/34338661734/events/', filename: 'eventbrite/eventbrite_ardc.json' },
     { url: 'https://www.eventbriteapi.com/v3/organizations/34338661734/events/', filename: 'eventbrite/eventbrite_ardc_2.json' },
     { url: 'https://www.eventbriteapi.com/v3/organizations/34338661734/events/?status=live', filename: 'eventbrite/eventbrite_ardc_2.json' },
     { url: 'https://www.eventbriteapi.com/v3/organizers/14317910674/', filename: 'eventbrite/organizer_14317910674.json' },
     { url: 'https://www.eventbriteapi.com/v3/organizers/8082048069/', filename: 'eventbrite/organizer_8082048069.json' },
     { url: 'https://www.eventbriteapi.com/v3/venues/88342919/', filename: 'eventbrite/venue_88342919.json' },
     { url: 'https://www.eventbriteapi.com/v3/categories/', filename: 'eventbrite/categories.json' },
     { url: 'https://www.eventbriteapi.com/v3/categories/101/', filename: 'eventbrite/categories_101.json' },
     { url: 'https://www.eventbriteapi.com/v3/categories/102/', filename: 'eventbrite/categories_102.json' },
     { url: 'https://www.eventbriteapi.com/v3/formats/', filename: 'eventbrite/formats.json' },
     { url: 'https://dummy.com', status: 404 },
     { url: 'https://dummy.com/events.csv', status: 404 },
     { url: 'https://app.com/materials/material3.html' },
     { url: 'https://dummy.com/materials.csv', status: 404 },
     { url: 'https://zenodo.org/api/records/?sort=mostrecent&ommunities=australianbiocommons-training&page=2&size=10', status: 404 },
     { url: 'https://zenodo.org/api/records/?communities=dummy', status: 404 },
     { url: 'https://missing.org/sitemap.xml', status: 404 },
     { url: 'https://pawsey.org.au/events/?ical=true', status: 404 },
     { url: 'https://www.eventbriteapi.com/v3/organizations/34338661734', status: 404 }].each do |opts|
      url = opts.delete(:url)
      method = opts.delete(:method) || :get
      opts[:body] = File.open(Rails.root.join( 'test', 'fixtures', 'files', 'ingestion', opts.delete(:filename))) if opts.key?(:filename)
      opts[:status] ||= 200
      opts[:headers] ||= {}

      WebMock.stub_request(method, url).to_return(opts)
    end
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

  def assert_permitted(policy, user, action, *opts)
    policy.new(Pundit::CurrentContext.new(user, request), *opts).send(action)
  end

  def refute_permitted(*args)
    !assert_permitted(*args)
  end

  def mock_timezone(tz = ActiveSupport::TimeZone.all.sample.tzinfo.identifier)
    @_prev_tz = ENV['TZ']  # Time zone should not affect test result
    ENV['TZ'] = tz
  end

  def reset_timezone
    ENV['TZ'] = @_prev_tz
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
