require 'test_helper'

class CookieConsentIntegrationTest < ActionDispatch::IntegrationTest
  test 'cookie consent banner shown' do
    with_settings({ require_cookie_consent: true }) do
      get root_path

      cookie_consent = CookieConsent.new(cookies)
      refute cookie_consent.given?
      assert cookie_consent.show_banner?
      assert_select '#cookie-banner' do
        assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'necessary')
        assert_select 'a.btn[href=?]', cookies_consent_path(allow: all_options), count: 0
      end
    end
  end

  test 'cookie consent banner shown with tracking option if analytics enabled' do
    with_settings({ require_cookie_consent: true, analytics_enabled: true }) do
      get root_path

      assert_select '#cookie-banner' do
        assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'necessary')
        assert_select 'a.btn[href=?]', cookies_consent_path(allow: all_options)
      end
    end
  end

  test 'cookie consent banner not shown if not required' do
    with_settings({ require_cookie_consent: false }) do
      get root_path

      cookie_consent = CookieConsent.new(cookies)
      refute cookie_consent.given?
      refute cookie_consent.show_banner?
      assert_select '#cookie-banner', count: 0
    end
  end

  test 'cookie consent banner not shown if already consented' do
    with_settings({ require_cookie_consent: true }) do
      post cookies_consent_path, params: { allow: all_options }

      get root_path

      cookie_consent = CookieConsent.new(cookies)
      assert_equal ['necessary', 'tracking'], cookie_consent.options
      assert cookie_consent.given?
      assert_select '#cookie-banner', count: 0
    end
  end

  test 'analytics code not present if only necessary cookies allowed' do
    with_settings({ require_cookie_consent: true, analytics_enabled: true }) do
      post cookies_consent_path, params: { allow: 'necessary' }

      get root_path

      assert_equal ['necessary'], CookieConsent.new(cookies).options
      assert_select '#ga-script', count: 0
    end
  end

  test 'analytics code present if only all cookies allowed' do
    with_settings({ require_cookie_consent: true, analytics_enabled: true }) do
      post cookies_consent_path, params: { allow: all_options }

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
      assert_equal ['necessary'], cookie_consent.options
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
      assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'none')
      assert_select 'a.btn[href=?]', cookies_consent_path(allow: 'necessary')
      assert_select 'a.btn[href=?]', cookies_consent_path(allow: all_options)

      post cookies_consent_path, params: { allow: 'necessary' }

      follow_redirect!
      assert_select '#flash-container .alert-danger', count: 0

      get cookies_consent_path

      assert_response :success
      assert_select '#cookie-consent-level', text: /No cookie consent/, count: 0
      assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics/, count: 0
      assert_select '#cookie-consent-level li', text: /Cookies necessary/

      post cookies_consent_path, params: { allow: all_options }

      get cookies_consent_path

      assert_response :success
      assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics/
      assert_select '#cookie-consent-level li', text: /Cookies necessary/
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
      assert_select 'a.btn[href=?]', cookies_consent_path(allow: all_options)

      post cookies_consent_path, params: { allow: all_options }

      get cookies_consent_path
      assert_response :success

      assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics/
      assert_select '#cookie-consent-level li', text: /Cookies necessary/
    end
  end

  test 'setting invalid cookie preferences shows an error' do
    with_settings({ require_cookie_consent: true }) do
      post cookies_consent_path, params: { allow: 'banana sandwich' }

      follow_redirect!

      assert_select '#flash-container .alert-danger', text: /Invalid cookie consent option provided/
    end
  end

  test 'revoke consent' do
    with_settings({ require_cookie_consent: true, analytics_enabled: true }) do
      post cookies_consent_path, params: { allow: 'necessary' }
      follow_redirect!
      assert_select '#flash-container .alert-danger', count: 0

      get cookies_consent_path
      assert_response :success

      assert_select '#cookie-consent-level', text: /No cookie consent/, count: 0
      assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics/, count: 0
      assert_select '#cookie-consent-level li', text: /Cookies necessary/
      assert_select '#cookie-banner', count: 0

      post cookies_consent_path, params: { allow: 'none' }
      follow_redirect!
      assert_select '#flash-container .alert-danger', count: 0

      get cookies_consent_path
      assert_response :success

      assert_select '#cookie-consent-level', text: /No cookie consent/
      assert_select '#cookie-consent-level li', text: /Cookies required for Google Analytics/, count: 0
      assert_select '#cookie-consent-level li', text: /Cookies necessary/, count: 0
      assert_select '#cookie-banner'
    end
  end

  test 'cookie consent cookie set with long expiry' do
    with_settings({ require_cookie_consent: true }) do
      post cookies_consent_path, params: { allow: all_options }
    end

    assert cookies.get_cookie('cookie_consent').expires > 1.year.from_now
  end

  test 'no link tracking if consent not given' do
    event = events(:one)
    material = materials(:good_material)
    trainer = profiles(:trainer_one_profile)

    with_settings({ require_cookie_consent: true }) do
      post cookies_consent_path, params: { allow: 'necessary' }

      get event_path(event)

      assert_select 'a.btn', text: 'View event' do
        assert_select '[data-trackable]', count: 0
        assert_select '[data-trackable-id]', count: 0
      end

      get material_path(material)

      assert_select 'a.btn', text: 'View material' do
        assert_select '[data-trackable]', count: 0
        assert_select '[data-trackable-id]', count: 0
      end

      get trainer_path(trainer)
      assert_select 'a[href=?]', trainer.orcid do
        assert_select '[data-trackable]', count: 0
        assert_select '[data-trackable-id]', count: 0
      end

      assert_select 'a[href=?]', trainer.website do
        assert_select '[data-trackable]', count: 0
        assert_select '[data-trackable-id]', count: 0
      end
    end
  end

  test 'link tracking if consent given' do
    event = events(:one)
    material = materials(:good_material)
    trainer = profiles(:trainer_one_profile)

    with_settings({ require_cookie_consent: true }) do
      post cookies_consent_path, params: { allow: all_options }

      get event_path(event)

      assert_select 'a.btn', text: 'View event' do
        assert_select '[data-trackable]'
        assert_select '[data-trackable-id=?]', event.id.to_s
        assert_select '[data-trackable-type=?]', 'Event'
      end

      get material_path(material)

      assert_select 'a.btn', text: 'View material' do
        assert_select '[data-trackable]'
        assert_select '[data-trackable-id=?]', material.id.to_s
        assert_select '[data-trackable-type=?]', 'Material'
      end

      get trainer_path(trainer)
      assert_select 'a[href=?]', trainer.orcid do
        assert_select '[data-trackable]'
        assert_select '[data-trackable-id]', count: 0
      end

      assert_select 'a[href=?]', trainer.website do
        assert_select '[data-trackable]'
        assert_select '[data-trackable-id]', count: 0
      end
    end
  end

  private

  def all_options
    CookieConsent::OPTIONS.join(',')
  end
end
