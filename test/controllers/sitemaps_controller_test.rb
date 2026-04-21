require 'test_helper'

class SitemapsControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'renders global sitemap when spaces feature is disabled' do
    with_settings(feature: { spaces: false }) do
      get :index
    end

    urls = sitemap_urls
    assert_includes urls, 'http://mytess.training/about'
    assert_not_includes urls, 'http://plants.mytess.training/about'
  end

  test 'renders global sitemap for default space when spaces feature is enabled' do
    with_settings(feature: { spaces: true }) do
      get :index
    end

    urls = sitemap_urls
    assert_includes urls, 'http://mytess.training/about'
    assert_not_includes urls, 'http://plants.mytess.training/about'
  end

  test 'renders space-specific sitemap when request is for a known space host' do
    space = spaces(:plants)
    with_settings(feature: { spaces: true }) do
      with_host(space.host) do
        get :index
      end
    end

    urls = sitemap_urls
    assert_not_includes urls, 'http://mytess.training/about'
    assert_includes urls, 'http://plants.mytess.training/about'
  end

  private

  def sitemap_urls
    parser = SitemapParser.new('', recurse: true)
    parser.instance_variable_set(:@raw_sitemap, @response.body)
    parser.to_a
  end
end
