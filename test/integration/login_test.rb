require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest

  test 'can log in with username' do
    user = users(:regular_user)

    get '/users/sign_in'

    post '/users/sign_in', params: { 'user[login]' => user.username, 'user[password]' => 'hello' }
    follow_redirect!

    assert_equal '/', path
    assert_select '.user-options > a:first', user.username
  end

  test 'can log in with email address' do
    user = users(:regular_user)

    get '/users/sign_in'

    post '/users/sign_in', params: { 'user[login]' => user.email, 'user[password]' => 'hello' }
    follow_redirect!

    assert_equal '/', path
    assert_select '.user-options > a:first', user.username
  end

end
