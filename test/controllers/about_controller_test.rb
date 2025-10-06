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
