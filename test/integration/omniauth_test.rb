require 'test_helper'

class OmniauthTest < ActionDispatch::IntegrationTest

  setup do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:oidc] = nil
    # request.env["devise.mapping"] = Devise.mappings[:user]
    # request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:elixir_aai]
  end

  test 'AAF authentication redirects new users to edit profile page' do
    OmniAuth.config.mock_auth[:oidc] = OmniAuth::AuthHash.new(
        {
            provider: 'oidc',
            uid: '0123456789abcdcef',
            info: {
                email: 'aai@example.com',
                nickname: 'aaf_user',
                first_name: 'AAF',
                last_name: 'User'
            }
        })

    post '/users/auth/oidc'

    follow_redirect! # OmniAuth redirect
    follow_redirect! # CallbacksController edit profile redirect

    assert_equal "/users/aaf_user/edit", path
    assert_select '.user-options > a:first', 'aaf_user'
    assert_select '#user_profile_attributes_firstname[value=?]', 'AAF'
    assert_select '#user_profile_attributes_surname[value=?]', 'User'
  end

  test 'AAF authentication redirects existing users to home page' do
    user = users(:existing_aaf_user)
    OmniAuth.config.mock_auth[:oidc] = OmniAuth::AuthHash.new(
        {
            provider: 'oidc',
            uid: user.uid,
            info: {
                email: user.email,
                nickname: user.username,
            }
        })

    post '/users/auth/oidc'

    follow_redirect! # OmniAuth redirect
    follow_redirect! # CallbacksController sign_in_and_redirect

    assert_equal '/', path
    assert_select '.user-options > a:first', user.username
  end

  test 'Registering via AAF does not duplicate existing usernames' do
    existing_user = users(:regular_user)

    OmniAuth.config.mock_auth[:oidc] = OmniAuth::AuthHash.new(
        {
            provider: 'oidc',
            uid: '0123456789abcdcef',
            info: {
                email: 'aai@example.com',
                nickname: existing_user.username,
                first_name: 'AAF',
                last_name: 'User'
            }
        })

    post '/users/auth/oidc'

    follow_redirect!
    follow_redirect!

    expected_username = "#{existing_user.username}1" # Adds 1 to end of name!

    assert_equal "/users/#{expected_username.downcase}/edit", path
    assert_select '.user-options > a:first', expected_username
  end

  test 'AAF authentication can link to an existing non-AAI user' do
    user = users(:regular_user)

    assert_nil user.provider
    assert_nil user.uid

    old_password = user.encrypted_password

    OmniAuth.config.mock_auth[:oidc] = OmniAuth::AuthHash.new(
        {
            provider: 'oidc',
            uid: '9876',
            info: {
                email: user.email,
                nickname: 'something-different',
            }
        })

    post '/users/auth/oidc'

    follow_redirect! # OmniAuth redirect
    follow_redirect! # CallbacksController sign_in_and_redirect

    user = user.reload

    assert_equal '/', path
    assert_select '.user-options > a:first', user.username

    assert_equal 'oidc', user.provider
    assert_equal '9876', user.uid
    assert_not_equal 'something-different', user.username, 'Username should have been preserved!'
    assert_equal old_password, user.encrypted_password, 'Password should have been preserved!'
  end

  test 'AAF authentication requires POST' do
    OmniAuth.config.mock_auth[:oidc] = OmniAuth::AuthHash.new(
        {
            provider: 'oidc',
            uid: '0123456789abcdcef',
            info: {
                email: 'aai@example.com',
                nickname: 'aaf_user',
                first_name: 'AAF',
                last_name: 'User'
            }
        })

    get '/users/auth/oidc'

    assert_response :not_found
  end

  test 'Can log in through AAF with multiple email addresses' do
    user = users(:existing_aaf_user)
    OmniAuth.config.mock_auth[:oidc] = OmniAuth::AuthHash.new(
        {
            provider: 'oidc',
            uid: user.uid,
            info: {
                email: user.email,
                nickname: user.username,
            }
        })

    post '/users/auth/oidc'

    follow_redirect! # OmniAuth redirect
    follow_redirect! # CallbacksController sign_in_and_redirect

    assert_equal '/', path
    assert_select '.user-options > a:first', user.username

    OmniAuth.config.mock_auth[:oidc] = OmniAuth::AuthHash.new(
        {
            provider: 'oidc',
            uid: user.uid,
            info: {
                email: "blablablablalbal@emaildomain.golf",
                nickname: "bieberfan1997",
            }
        })

    post '/users/auth/oidc'

    follow_redirect! # OmniAuth redirect
    follow_redirect! # CallbacksController sign_in_and_redirect

    assert_equal '/', path
    assert_select '.user-options > a:first', user.username
  end
end
