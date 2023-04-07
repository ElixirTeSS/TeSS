require 'test_helper'

class LoginTest < ActionDispatch::IntegrationTest
  test 'can log in with username' do
    user = users(:regular_user)
    login_user(user.username, user.username, 'hello')
  end

  test 'can log in with email address' do
    user = users(:regular_user)
    login_user(user.username, user.email, 'hello')
  end

  test 'can log in case insensitively' do
    user = User.create!(username: 'neWuSer1996', email: 'neWUSer1996@email.com', password: '12345678',
                        processing_consent: '1')

    login_user(user.username, 'neWuSer1996', '12345678')
    logout_user
    login_user(user.username, 'NEWUSER1996', '12345678')
    logout_user
    login_user(user.username, 'newuser1996', '12345678')
    logout_user
    login_user(user.username, 'neWUSer1996@email.com', '12345678')
    logout_user
    login_user(user.username, 'NEWUSER1996@email.com', '12345678')
    logout_user
    login_user(user.username, 'newuser1996@email.com', '12345678')
    logout_user
  end

  private

  def login_user(username, identifier, password)
    get '/users/sign_in'
    post '/users/sign_in', params: { 'user[login]' => identifier, 'user[password]' => password }
    follow_redirect!
    assert_equal '/', path
    assert_select '#user-menu .dropdown-toggle', username
    assert_equal 'Logged in successfully.', flash[:notice]
  end

  def logout_user
    delete '/users/sign_out'
    follow_redirect!
    assert_equal '/', path
    assert_select '#navbar-collapse .dropdown-toggle strong', 'Log In'
    assert_equal 'Logged out successfully.', flash[:notice]
  end
end
