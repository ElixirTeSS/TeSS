require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  setup do
    WebMock.stub_request(:any, 'http://200host.com').to_return(status: 200, body: 'hi')
    WebMock.stub_request(:any, 'http://404host.com').to_return(status: 404, body: 'hi')
    WebMock.stub_request(:any, 'http://500host.com').to_return(status: 500, body: 'hi')
    WebMock.stub_request(:any, 'http://slowhost.com').to_timeout
    WebMock.stub_request(:any, 'http://notrealhost.goldfish').to_raise(SocketError)
    WebMock.stub_request(:any, 'http://badformathost.com').to_return(status: 200,
                                                                     body: '<h1>Not really JSON</h1>',
                                                                     headers: { content_type: 'application/json' })

    sign_in users(:regular_user)
  end

  test 'can check URLs' do
    get :test_url, params: { url: 'http://200host.com', format: :json }
    assert_equal 200, JSON.parse(response.body)['code']

    get :test_url, params: { url: 'http://404host.com', format: :json }
    assert_equal 404, JSON.parse(response.body)['code']

    get :test_url, params: { url: 'http://500host.com', format: :json }
    assert_equal 500, JSON.parse(response.body)['code']

    get :test_url, params: { url: 'http://badformathost.com', format: :json }
    assert_equal 200, JSON.parse(response.body)['code']

    get :test_url, params: { url: 'http://slowhost.com', format: :json }
    assert_equal 'Could not access the given URL', JSON.parse(response.body)['message']

    get :test_url, params: { url: 'http://notrealhost.goldfish', format: :json }
    assert_equal 'Could not access the given URL', JSON.parse(response.body)['message']

    with_net_connection do
      get :test_url, params: { url: 'http://192.168.0.1', format: :json }
      assert_equal 'Could not access the given URL', JSON.parse(response.body)['message']
    end
  end

end
