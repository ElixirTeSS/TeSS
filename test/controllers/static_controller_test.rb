require 'test_helper'

class StaticControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  test "should get home" do
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
end
