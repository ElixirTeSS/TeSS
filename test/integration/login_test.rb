require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest

  def login_user(username, identifier, password)
    get '/users/sign_in'
    post '/users/sign_in', params: { 'user[login]' => identifier, 'user[password]' => password }
    follow_redirect!
    assert_equal '/', path
    assert_select '.user-options > a:first', username
    assert_equal 'Logged in successfully.', flash[:notice]
  end

  test 'can log in with username' do
    user = users(:regular_user)
    login_user(user.username, user.username, 'hello')
  end

  test 'can log in with email address' do
    user = users(:regular_user)
    login_user(user.username, user.email, 'hello')
  end

end
