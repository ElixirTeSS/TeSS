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
end
