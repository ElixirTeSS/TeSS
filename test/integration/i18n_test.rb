require 'test_helper'

class I18n_Test < ActionDispatch::IntegrationTest

  setup do
    I18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
    I18n.available_locales = [:en, :'en-AU', :'en-EU']
    I18n.default_locale = :en
    @user = users(:regular_user)
  end

  teardown do
    I18n.locale = :en
  end

  test 'can log in with email address' do
    get '/users/sign_in'
    post '/users/sign_in', params: { 'user[login]' => @user.email, 'user[password]' => 'hello' }

    follow_redirect!
    assert_equal 'Logged in successfully.', flash[:notice]
  end

  test 'can log in with email address (en-AU)' do
    I18n.locale = :'en-AU'
    get '/users/sign_in'
    post '/users/sign_in', params: { 'user[login]' => @user.email, 'user[password]' => 'hello' }

    follow_redirect!
    assert_equal 'Logged in successfully.', flash[:notice]
  end

  test 'can logout (en-AU)' do
    I18n.locale = :'en-AU'
    get '/users/sign_in'
    post '/users/sign_in', params: { 'user[login]' => @user.email, 'user[password]' => 'hello' }

    delete '/users/sign_out'
    follow_redirect!
    assert_equal 'Logged out successfully.', flash[:notice]
  end


end
