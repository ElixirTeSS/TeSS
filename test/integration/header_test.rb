require 'test_helper'

class HeaderTest < ActionDispatch::IntegrationTest
  test 'includes valid Content-Security-Policy header' do
    get '/'

    assert_response :success
    assert response.headers.key?('Content-Security-Policy')
    assert_includes response.headers['Content-Security-Policy'], "default-src 'self' https:;"
    assert_includes response.headers['Content-Security-Policy'], "script-src 'self' https: 'unsafe-inline';"
  end

  test 'includes valid Feature-Policy header' do
    get '/'

    assert_response :success
    assert response.headers.key?('Feature-Policy')
    assert_includes response.headers['Feature-Policy'], "fullscreen 'self';"
    assert_includes response.headers['Feature-Policy'], "camera 'none';"
  end
end
