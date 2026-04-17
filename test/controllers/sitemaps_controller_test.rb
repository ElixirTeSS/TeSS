require 'test_helper'

class SitemapsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'redirects to global sitemap when spaces feature is disabled' do
    with_settings(feature: { spaces: false }) do
      get :index
    end
    assert_redirected_to '/sitemaps/sitemap.xml'
  end

  test 'redirects to global sitemap for default space when spaces feature is enabled' do
    with_settings(feature: { spaces: true }) do
      get :index
    end
    assert_redirected_to '/sitemaps/sitemap.xml'
  end

  test 'redirects to space-specific sitemap when request is for a known space host' do
    space = spaces(:plants)
    with_settings(feature: { spaces: true }) do
      with_host(space.host) do
        get :index
      end
    end
    assert_redirected_to "/sitemaps/#{space.host}/sitemap.xml"
  end
end
