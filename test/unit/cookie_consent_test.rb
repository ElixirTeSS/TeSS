require 'test_helper'

class CookieConsentTest < ActiveSupport::TestCase

  test 'should check if consent required?' do
    with_settings({ require_cookie_consent: false }) do
      refute CookieConsent.required?

      cookie_consent = CookieConsent.new({})
      refute cookie_consent.required?
      assert cookie_consent.given?
      assert cookie_consent.allow_all?
      assert cookie_consent.allow_tracking?
      assert cookie_consent.allow_necessary?
    end

    with_settings({ require_cookie_consent: true }) do
      assert CookieConsent.required?

      cookie_consent = CookieConsent.new({})
      assert cookie_consent.required?
      refute cookie_consent.given?
      refute cookie_consent.allow_all?
      refute cookie_consent.allow_tracking?
      refute cookie_consent.allow_necessary?

      cookie_consent = CookieConsent.new({ cookie_consent: 'all' })
      assert cookie_consent.required?
      assert cookie_consent.given?
      assert cookie_consent.allow_all?
      assert cookie_consent.allow_tracking?
      assert cookie_consent.allow_necessary?

      cookie_consent = CookieConsent.new({ cookie_consent: 'necessary' })
      assert cookie_consent.required?
      assert cookie_consent.given?
      refute cookie_consent.allow_all?
      refute cookie_consent.allow_tracking?
      assert cookie_consent.allow_necessary?

      cookie_consent = CookieConsent.new({ cookie_consent: 'banana' })
      assert cookie_consent.required?
      refute cookie_consent.given?
      refute cookie_consent.allow_all?
      refute cookie_consent.allow_tracking?
      refute cookie_consent.allow_necessary?
    end
  end

  test 'should get and set consent level, and validate level' do
    store = Rack::Test::CookieJar.new
    cookie_consent = CookieConsent.new(store)

    assert_nil cookie_consent.level
    refute cookie_consent.given?

    cookie_consent.level = 'necessary'
    assert_equal 'necessary', cookie_consent.level
    assert cookie_consent.given?

    cookie_consent.level = 'all'
    assert_equal 'all', cookie_consent.level
    assert cookie_consent.given?

    cookie_consent.level = 'banana'
    assert_equal 'all', cookie_consent.level, 'Should not change if invalid level provided'
    assert cookie_consent.given?
  end
end
