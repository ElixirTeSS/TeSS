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

  WebMock.disable_net_connect!(allow_localhost: true)

  # Mock remote images so paperclip doesn't break:
  def mock_images
    WebMock.stub_request(:any, /http\:\/\/example\.com\/(.+)\.png/).to_return(
        status: 200, body: File.read('test/fixtures/files/image.png'), headers: { content_type: 'image/png' }
    )
  end

end
