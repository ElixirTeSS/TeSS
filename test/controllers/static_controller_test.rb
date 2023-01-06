require 'test_helper'

class StaticControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get home' do
    get :home
    assert_response :success
  end

  test 'should show tabs for enabled features' do
    features = TeSS::Config.feature.dup

    TeSS::Config.feature['events'] = true
    TeSS::Config.feature['materials'] = true
    TeSS::Config.feature['e-learnings'] = true
    TeSS::Config.feature['workflows'] = true
    TeSS::Config.feature['collections'] = true
    TeSS::Config.feature['providers'] = true
    TeSS::Config.feature['trainers'] = true
    TeSS::Config.feature['nodes'] = true

    get :home

    assert_select 'ul.nav.navbar-nav' do
      assert_select 'li a[href=?]', workflows_path
      assert_select 'li a[href=?]', events_path
      assert_select 'li a[href=?]', materials_path
      assert_select 'li a[href=?]', workflows_path
      assert_select 'li a[href=?]', collections_path
      assert_select 'li a[href=?]', content_providers_path
      assert_select 'li a[href=?]', trainers_path
      assert_select 'li a[href=?]', nodes_path
    end
  ensure
    TeSS::Config.feature = features
  end

  test 'should not show tabs for disabled features' do
    features = TeSS::Config.feature.dup

    TeSS::Config.feature['events'] = false
    TeSS::Config.feature['materials'] = false
    TeSS::Config.feature['e-learnings'] = false
    TeSS::Config.feature['workflows'] = false
    TeSS::Config.feature['collections'] = false
    TeSS::Config.feature['providers'] = false
    TeSS::Config.feature['trainers'] = false
    TeSS::Config.feature['nodes'] = false

    get :home

    assert_select 'ul.nav.navbar-nav' do
      assert_select 'li a[href=?]', workflows_path, count: 0
      assert_select 'li a[href=?]', events_path, count: 0
      assert_select 'li a[href=?]', materials_path, count: 0
      assert_select 'li a[href=?]', workflows_path, count: 0
      assert_select 'li a[href=?]', collections_path, count: 0
      assert_select 'li a[href=?]', content_providers_path, count: 0
      assert_select 'li a[href=?]', trainers_path, count: 0
      assert_select 'li a[href=?]', nodes_path, count: 0
    end
  ensure
    TeSS::Config.feature = features
  end

  test 'should allow configuration of home page sections' do
    site_settings = TeSS::Config.site.dup
    site_settings['home_page'] = {
      'catalogue_blocks': false,
      'provider_carousel': false,
      'featured_providers': nil,
      'faq': [],
      'promo_blocks': false
    }

    with_settings({ site: site_settings }) do
      get :home
      assert_select 'section#catalogue', count: 0
      assert_select 'section#providers', count: 0
      assert_select 'section#faq', count: 0
      assert_select 'ul#promo-blocks', count: 0
    end

    site_settings['home_page']['catalogue_blocks'] = true
    with_settings({ site: site_settings }) do
      get :home
      assert_select 'section#catalogue', count: 1
      assert_select 'section#providers', count: 0
      assert_select 'section#faq', count: 0
      assert_select 'ul#promo-blocks', count: 0
    end

    site_settings['home_page']['provider_carousel'] = true
    provider = content_providers(:goblet)
    provider2 = content_providers(:iann)
    site_settings['home_page']['featured_providers'] = [provider, provider2]
    with_settings({ site: site_settings }) do
      get :home
      assert_select 'section#catalogue', count: 1
      assert_select 'section#providers', count: 1
      assert_select 'section#providers .item a[href=?]', content_provider_path(provider)
      assert_select 'section#providers .item a[href=?]', content_provider_path(provider2)
      assert_select 'section#faq', count: 0
      assert_select 'ul#promo-blocks', count: 0
    end

    site_settings['home_page']['faq'] = ['who', 'why']
    with_settings({ site: site_settings }) do
      get :home
      assert_select 'section#catalogue', count: 1
      assert_select 'section#providers', count: 1
      assert_select 'section#faq', count: 1
      assert_select 'section#faq .question', count: 2
      assert_select 'ul#promo-blocks', count: 0
    end

    site_settings['home_page']['promo_blocks'] = true
    with_settings({ site: site_settings }) do
      get :home
      assert_select 'section#catalogue', count: 1
      assert_select 'section#providers', count: 1
      assert_select 'section#faq', count: 1
      assert_select 'ul#promo-blocks', count: 1
    end
  end
end
