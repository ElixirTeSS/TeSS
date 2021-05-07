require 'simplecov'
require 'codacy-coverage'
Codacy::Reporter.start
SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
                                                                    SimpleCov::Formatter::HTMLFormatter,
                                                                    Codacy::Formatter,
                                                                ])
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

  WebMock.disable_net_connect!(allow_localhost: true, allow: 'api.codacy.com')

  # Mock remote images so paperclip doesn't break:
  def mock_images
    WebMock.stub_request(:any, /http\:\/\/example\.com\/(.+)\.png/).to_return(
        status: 200, body: File.read(File.join(Rails.root, 'test/fixtures/files/image.png')), headers: { content_type: 'image/png' }
    )

    WebMock.stub_request(:any, "http://image.host/another_image.png").to_return(
        status: 200, body: File.read(File.join(Rails.root, 'test/fixtures/files/another_image.png')), headers: { content_type: 'image/png' }
    )

    WebMock.stub_request(:any, "http://malicious.host/image.png").to_return(
        status: 200, body: File.read(File.join(Rails.root, 'test/fixtures/files/bad.js')), headers: { content_type: 'image/png' }
    )

    WebMock.stub_request(:any, "http://text.host/text.txt").to_return(
        status: 200, body: File.read(File.join(Rails.root, 'test/fixtures/files/text.txt')), headers: { content_type: 'text/plain' }
    )

    WebMock.stub_request(:any, "http://404.host/image.png").to_return(status: 404)

    WebMock.stub_request(:get, "https://bio.tools/api/tool?q=Training%20Material%20Example").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})

    WebMock.stub_request(:get, "https://bio.tools/api/tool?q=Material%20with%20suggestions").
        with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
        to_return(:status => 200, :body => "", :headers => {})
  end

  def mock_biotools
    biotools_file = File.read("#{Rails.root}/test/fixtures/files/annotation.json")
    WebMock.stub_request(:get, /data.bioontology.org/).
      to_return(:status => 200, :headers => {},  :body => biotools_file)
  end

  def mock_nominatim
    nominatim_file = File.read("#{Rails.root}/test/fixtures/files/nominatim.json")
    WebMock.stub_request(:get, /nominatim.openstreetmap.org/).
        to_return(:status => 200, :headers => {}, :body => nominatim_file)
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

    metaclass = class << self; self; end

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
