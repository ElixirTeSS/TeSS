require 'test_helper'

class StaticControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  test "should get home" do
    get :home
    assert_response :success
  end

  test 'should show tabs for enabled features' do
    features = { 'events': true,
                 'materials': true,
                 'e-learnings': true,
                 'workflows': true,
                 'collections': true,
                 'providers': true,
                 'trainers': true,
                 'nodes': true }

    with_settings(feature: features) do
      get :home
    end

    assert_select 'ul.nav.navbar-nav' do
      assert_select 'li a[href=?]', workflows_path
      assert_select 'li a[href=?]', events_path
      assert_select 'li a[href=?]', materials_path
      assert_select 'li a[href=?]', elearning_materials_path
      assert_select 'li a[href=?]', workflows_path
      assert_select 'li a[href=?]', collections_path
      assert_select 'li a[href=?]', content_providers_path
      assert_select 'li a[href=?]', trainers_path
      assert_select 'li a[href=?]', nodes_path
    end
  end

  test 'should not show tabs for disabled features' do
    features = { 'events': false,
                 'materials': false,
                 'e-learnings': false,
                 'workflows': false,
                 'collections': false,
                 'providers': false,
                 'trainers': false,
                 'nodes': false }

    with_settings(feature: features) do
      get :home
    end

    assert_select 'ul.nav.navbar-nav' do
      assert_select 'li a[href=?]', workflows_path, count: 0
      assert_select 'li a[href=?]', events_path, count: 0
      assert_select 'li a[href=?]', materials_path, count: 0
      assert_select 'li a[href=?]', elearning_materials_path, count: 0
      assert_select 'li a[href=?]', workflows_path, count: 0
      assert_select 'li a[href=?]', collections_path, count: 0
      assert_select 'li a[href=?]', content_providers_path, count: 0
      assert_select 'li a[href=?]', trainers_path, count: 0
      assert_select 'li a[href=?]', nodes_path, count: 0
    end
  end
end
