# frozen_string_literal: true

require 'test_helper'

class StaticControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get home' do
    get :home

    assert_response :success
  end

  test 'should show tabs for enabled features' do
    features = { events: true,
                 materials: true,
                 elearning_materials: true,
                 workflows: true,
                 collections: true,
                 content_providers: true,
                 trainers: true,
                 nodes: true }

    with_settings(feature: features) do
      get :home
    end

    assert_select 'ul.nav.navbar-nav' do
      assert_select 'li a[href=?]', about_path
      assert_select 'li a[href=?]', events_path
      assert_select 'li a[href=?]', materials_path
      assert_select 'li a[href=?]', workflows_path
      assert_select 'li a[href=?]', elearning_materials_path
      assert_select 'li a[href=?]', collections_path
      assert_select 'li.dropdown.directory-menu' do
        assert_select 'li a[href=?]', content_providers_path
        assert_select 'li a[href=?]', trainers_path
        assert_select 'li a[href=?]', nodes_path
      end
    end
  end

  test 'should not show tabs for disabled features' do
    features = { events: false,
                 materials: false,
                 elearning_materials: false,
                 workflows: false,
                 collections: false,
                 content_providers: false,
                 trainers: false,
                 nodes: false }

    with_settings(feature: features) do
      get :home
    end

    assert_select 'ul.nav.navbar-nav' do
      assert_select 'li a[href=?]', about_path
      assert_select 'li a[href=?]', events_path, count: 0
      assert_select 'li a[href=?]', materials_path, count: 0
      assert_select 'li a[href=?]', workflows_path, count: 0
      assert_select 'li a[href=?]', elearning_materials_path, count: 0
      assert_select 'li a[href=?]', collections_path, count: 0
      assert_select 'li a[href=?]', content_providers_path, count: 0
      assert_select 'li a[href=?]', trainers_path, count: 0
      assert_select 'li a[href=?]', nodes_path, count: 0
      assert_select 'li.dropdown.directory-menu', count: 0
    end
  end

  test 'should allow configuration of home page sections' do
    site_settings = TeSS::Config.site.dup
    site_settings['home_page'] = {
      catalogue_blocks: false,
      provider_carousel: false,
      featured_providers: nil,
      faq: [],
      promo_blocks: false
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

  test 'should allow configuration of tab order and directory' do
    features = { events: true,
                 materials: true,
                 elearning_materials: true,
                 workflows: true,
                 collections: true,
                 content_providers: true,
                 trainers: true,
                 nodes: true }

    with_settings(feature: features, site: { tab_order: ['materials', 'events'], directory_tabs: [] }) do
      get :home
      assert_select 'ul.nav.navbar-nav' do
        assert_select 'li:nth-child(1) a[href=?]', materials_path
        assert_select 'li:nth-child(2) a[href=?]', events_path
        assert_select 'li a[href=?]', about_path
        assert_select 'li a[href=?]', workflows_path
        assert_select 'li a[href=?]', elearning_materials_path
        assert_select 'li a[href=?]', collections_path
        assert_select 'li a[href=?]', content_providers_path
        assert_select 'li a[href=?]', trainers_path
        assert_select 'li a[href=?]', nodes_path
        assert_select 'li.dropdown.directory-menu', count: 0
      end
    end

    with_settings(feature: features, site: { tab_order: ['content_providers', 'about', 'materials', 'trainers'],
                                             directory_tabs: [] }) do
      get :home

      assert_select 'ul.nav.navbar-nav' do
        assert_select 'li:nth-child(1) a[href=?]', content_providers_path
        assert_select 'li:nth-child(2) a[href=?]', about_path
        assert_select 'li:nth-child(3) a[href=?]', materials_path
        assert_select 'li:nth-child(4) a[href=?]', trainers_path
        assert_select 'li a[href=?]', events_path
        assert_select 'li a[href=?]', workflows_path
        assert_select 'li a[href=?]', elearning_materials_path
        assert_select 'li a[href=?]', collections_path
        assert_select 'li a[href=?]', nodes_path
        assert_select 'li.dropdown.directory-menu', count: 0
      end
    end

    with_settings(feature: features, site: { tab_order: ['content_providers', 'about', 'materials', 'trainers'],
                                             directory_tabs: ['about', 'materials'] }) do
      get :home

      assert_select 'ul.nav.navbar-nav' do
        assert_select 'li:nth-child(1) a[href=?]', content_providers_path
        assert_select 'li:nth-child(2) a[href=?]', trainers_path
        assert_select 'li a[href=?]', events_path
        assert_select 'li a[href=?]', workflows_path
        assert_select 'li a[href=?]', elearning_materials_path
        assert_select 'li a[href=?]', collections_path
        assert_select 'li a[href=?]', nodes_path
        assert_select 'li.dropdown.directory-menu' do
          assert_select 'li:nth-child(1) a[href=?]', about_path
          assert_select 'li:nth-child(2) a[href=?]', materials_path
        end
      end
    end
  end

  test 'should hide unverified providers from carousel' do
    mock_images
    ContentProvider.destroy_all
    regular = users(:regular_user)
    unverified = users(:unverified_user)
    regular_provider = regular.content_providers.create!(title: 'Regular Provider',
                                                         image_url: 'http://example.com/goblet.png',
                                                         url: 'https://providers.com/p1')
    unverified_provider = unverified.content_providers.create!(title: 'Unverified Provider',
                                                               image_url: 'http://example.com/goblet.png',
                                                               url: 'https://providers.com/p2')
    another_provider = regular.content_providers.create!(title: 'Another Regular Provider',
                                                         image_url: 'http://example.com/goblet.png',
                                                         url: 'https://providers.com/p3')
    with_settings(site: { home_page: { provider_carousel: true } }) do
      get :home

      assert_select 'section#providers .item', count: 2
      assert_select 'section#providers .item a[href=?]', content_provider_path(regular_provider)
      assert_select 'section#providers .item a[href=?]', content_provider_path(unverified_provider), count: 0
      assert_select 'section#providers .item a[href=?]', content_provider_path(another_provider)
    end
  end
end
