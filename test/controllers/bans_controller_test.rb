require 'test_helper'

class BansControllerTest < ActionController::TestCase
  include Devise::Test::ControllerHelpers

  test 'should get new ban page if admin' do
    sign_in users(:admin)

    get :new, params: { user_id: users(:regular_user) }
    assert_response :success
  end

  test 'should not get new ban page if non-admin' do
    sign_in users(:another_regular_user)

    get :new, params: { user_id: users(:regular_user) }
    assert_response :forbidden
  end

  test 'should ban user if admin' do
    sign_in users(:admin)
    user = users(:regular_user)

    assert_difference('Ban.count', 1) do
      post :create, params: { user_id: user, ban: { reason: 'naughty', shadow: true } }
    end

    assert_redirected_to user
    assert user.shadowbanned?
  end

  test 'should not ban user if non-admin' do
    sign_in users(:another_regular_user)
    user = users(:regular_user)

    assert_no_difference('Ban.count') do
      post :create, params: { user_id: user, ban: { reason: 'naughty', shadow: true } }
    end

    assert_response :forbidden
    refute user.shadowbanned?
  end

  test 'should remove ban if admin' do
    sign_in users(:admin)
    user = users(:shadowbanned_user)

    assert_difference('Ban.count', -1) do
      delete :destroy, params: { user_id: user }
    end

    assert_redirected_to user
    refute user.shadowbanned?
  end

  test 'should not remove ban if non-admin' do
    sign_in users(:another_regular_user)
    user = users(:shadowbanned_user)

    assert_no_difference('Ban.count') do
      delete :destroy, params: { user_id: user }
    end

    assert_response :forbidden
    assert user.shadowbanned?
  end
end
