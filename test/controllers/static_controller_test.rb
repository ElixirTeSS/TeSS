require 'test_helper'

class StaticControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get home' do
    get :home
    assert_response :success
  end

  test 'should show tabs for enabled features' do
    features = { 'events': true,
                 'materials': true,
                 'elearning_materials': true,
                 'workflows': true,
                 'collections': true,
                 'content_providers': true,
                 'trainers': true,
                 'nodes': true }

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
    features = { 'events': false,
                 'materials': false,
                 'elearning_materials': false,
                 'workflows': false,
                 'collections': false,
                 'content_providers': false,
                 'trainers': false,
                 'nodes': false }

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

    site_settings['home_page']['faq'] = %w[who why]
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
    features = { 'events': true,
                 'materials': true,
                 'elearning_materials': true,
                 'workflows': true,
                 'collections': true,
                 'content_providers': true,
                 'trainers': true,
                 'nodes': true }

    with_settings(feature: features, site: { tab_order: %w[materials events], directory_tabs: [] }) do
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

    with_settings(feature: features, site: { tab_order: %w[content_providers about materials trainers],
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

    with_settings(feature: features, site: { tab_order: %w[content_providers about materials trainers],
                                             directory_tabs: %w[about materials] }) do
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

  test 'should show upcoming events' do
    my_events = [events(:one), events(:two)]
    my_events.each do |e|
      e.start = Time.zone.tomorrow
      e.end = Time.zone.tomorrow + 1.day
      e.save!
    end
    Event.stub(:search_and_filter, MockSearch.new(my_events)) do
      with_settings({ site: { home_page: { upcoming_events: 5 } } }) do
        get :home
        assert_select 'section#upcoming_events', count: 1
        assert_select 'section#upcoming_events h2', count: 1
        assert_select 'section#upcoming_events ul', count: 2
      end
    end
  end

  test 'should show latest materials' do
    my_materials = [materials(:good_material), materials(:interpro)]
    Material.stub(:search_and_filter, MockSearch.new(my_materials)) do
      with_settings({ site: { home_page: { latest_materials: 5 } } }) do
        get :home
        assert_select 'section#latest_materials', count: 1
        assert_select 'section#latest_materials h2', count: 1
        assert_select 'section#latest_materials ul', count: 2
      end
    end
  end

  test 'should show featured trainer' do
    with_settings({ site: { home_page: { featured_trainer: true } } }) do
      get :home
      assert_select 'section#featured_trainer', count: 1
      assert_select 'section#featured_trainer h2', count: 1
      assert_select 'section#featured_trainer li', count: 1
    end
  end

  test 'should show event counts in counter blocks' do
    params = events(:one).attributes.symbolize_keys
    params.delete(:id)
    params = params.merge({ start: Time.zone.now + 1.week, end: Time.zone.now + 1.week + 8.hours })
    111.times do |i|
      Event.create(params.merge(url: "#{params[:url]}##{i}"))
    end
    with_settings({ site: { home_page: { counters: true } } }) do
      get :home
      assert_select 'div#resource_count', text: '112', count: 1
    end
  end
end
