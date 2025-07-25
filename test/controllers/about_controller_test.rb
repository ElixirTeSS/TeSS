require 'test_helper'

class AboutControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get first about page' do
    get :tess
    assert_response :success
    assert_select 'li.about-page-category a[href=?]', registering_learning_paths_path, count: 1
  end

  test 'should get about us' do
    get :us
    assert_response :success
  end

  test 'should show correct funder logos in about us and footer' do
    funder_setting = [
      {
        'url': 'https://example.org/your-funders-website',
        'logo': 'https://example.org/your-funders-website/logo.png'
      },
      {
        'url': 'https://example.org/funder-footer',
        'logo': 'https://example.org/funder-footer/logo.png',
        'only': 'footer'
      },
      {
        'url': 'https://example.org/funder-about',
        'logo': 'https://example.org/funder-about/logo.png',
        'only': 'about'
      }
    ]
    
    with_settings(funders: funder_setting) do
      get :us
      assert_select '#funding' do
        assert_select 'a[htref=?]', 'https://example.org/your-funders-website' do
          assert_select 'img[src=?]', 'https://example.org/your-funders-website/logo.png'
        end
        assert_select 'a[htref=?]', 'https://example.org/funder-about' do
          assert_select 'img[src=?]', 'https://example.org/funder-about/logo.png'
        end
        assert_select 'a[htref=?]', 'https://example.org/funder-footer', count: 0
        assert_select 'img[src=?]', 'https://example.org/funder-footer/logo.png', count: 0
      end

      assert_select 'footer' do
        assert_select 'a[htref=?]', 'https://example.org/your-funders-website' do
          assert_select 'img[src=?]', 'https://example.org/your-funders-website/logo.png'
        end
        assert_select 'a[htref=?]', 'https://example.org/funder-footer' do
          assert_select 'img[src=?]', 'https://example.org/funder-footer/logo.png'
        end
        assert_select 'a[htref=?]', 'https://example.org/funder-about', count: 0
        assert_select 'img[src=?]', 'https://example.org/funder-about/logo.png', count: 0
      end
    end
  end

  test 'should get about registering' do
    get :registering
    assert_response :success
  end

  test 'should get about developers' do
    get :developers
    assert_response :success
  end

  test 'should get about learning paths' do
    get :learning_paths
    assert_response :success
  end

  test 'should not list learning path help if feature disabled' do
    with_settings(feature: { learning_paths: false }) do
      get :tess
      assert_response :success
      assert_select 'li.about-page-category a[href=?]', registering_learning_paths_path, count: 0
    end
  end

  test 'should access learning paths help directly even if feature disabled' do
    with_settings(feature: { learning_paths: false }) do
      get :learning_paths
      assert_response :success
    end
  end
end
