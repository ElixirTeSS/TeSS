require 'test_helper'

class CookieConsentIntegrationTest < ActionDispatch::IntegrationTest
  test 'cookie consent banner shown' do
    with_settings({ require_cookie_consent: true }) do
      get root_path

      assert_nil CookieConsent.new(cookies).level
      assert_select '#cookie-banner' do
        assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'necessary'), count: 0
        assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'all')
      end
    end
  end

  test 'cookie consent banner shown with tracking option if analytics enabled' do
    with_settings({ require_cookie_consent: true, analytics_enabled: true }) do
      get root_path

      assert_nil CookieConsent.new(cookies).level
      assert_select '#cookie-banner' do
        assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'necessary')
        assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'all')
      end
    end
  end

  test 'cookie consent banner not shown if not required' do
    with_settings({ require_cookie_consent: false }) do
      get root_path

      assert_nil CookieConsent.new(cookies).level
      assert_select '#cookie-banner', count: 0
    end
  end

  test 'cookie consent banner not shown if already consented' do
    with_settings({ require_cookie_consent: true }) do
      post cookies_consent_path, params: { allow: 'all' }

      get root_path

      cookie_consent = CookieConsent.new(cookies)
      assert_equal 'all', cookie_consent.level
      assert cookie_consent.given?
      assert_select '#cookie-banner', count: 0
    end
  end

  test 'analytics code not present if only necessary cookies allowed' do
    with_settings({ require_cookie_consent: true, analytics_enabled: true }) do
      post cookies_consent_path, params: { allow: 'necessary' }

      get root_path

      assert_equal 'necessary', CookieConsent.new(cookies).level
      assert_select '#ga-script', count: 0
    end
  end

  test 'analytics code present if only all cookies allowed' do
    with_settings({ require_cookie_consent: true, analytics_enabled: true }) do
      post cookies_consent_path, params: { allow: 'all' }

      get root_path

      assert CookieConsent.new(cookies).allow_tracking?
      assert_select '#ga-script', count: 1
    end
  end

  test 'analytics code present if cookie consent not required' do
    with_settings({ require_cookie_consent: false, analytics_enabled: true }) do
      post cookies_consent_path, params: { allow: 'necessary' }

      get root_path

      cookie_consent = CookieConsent.new(cookies)
      assert_equal 'necessary', cookie_consent.level
      assert cookie_consent.allow_tracking?
      assert_select '#ga-script', count: 1
    end
  end

  test 'can access and use cookie consent page as anonymous user' do
    with_settings({ require_cookie_consent: true, analytics_enabled: true }) do
      get cookies_consent_path

      assert_nil User.current_user
      assert_response :success
      assert_select '#cookie-consent-level', text: /No cookie consent/
      assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'necessary')
      assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'all')

      post cookies_consent_path, params: { allow: 'necessary' }

      get cookies_consent_path
      assert_response :success

      assert_select '#cookie-consent-level', text: /Only cookies necessary/

      post cookies_consent_path, params: { allow: 'all' }

      get cookies_consent_path
      assert_response :success

      assert_select '#cookie-consent-level', text: /All cookies/
    end
  end

  test 'can access cookie consent page as authenticated user' do
    user = users(:regular_user)
    post '/users/sign_in', params: { 'user[login]' => user.username, 'user[password]' => 'hello' }

    with_settings({ require_cookie_consent: true, analytics_enabled: true }) do
      get cookies_consent_path

      assert_equal user, User.current_user
      assert_response :success
      assert_select '#cookie-consent-level', text: /No cookie consent/
      assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'necessary')
      assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'all')

      post cookies_consent_path, params: { allow: 'all' }

      get cookies_consent_path
      assert_response :success

      assert_select '#cookie-consent-level', text: /All cookies/
    end
  end
end
