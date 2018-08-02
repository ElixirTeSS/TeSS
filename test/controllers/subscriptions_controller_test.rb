require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase

  include Devise::Test::ControllerHelpers

  test 'should list subscriptions for the logged-in user' do
    sign_in users(:regular_user)

    get :index

    assert_select '.subscription', count: 3
  end

  test "should not list other user's subscriptions" do
    sign_in users(:another_regular_user)

    get :index

    assert_select '.subscription', count: 0
  end

  test 'should not list subscriptions for anonymous user' do
    get :index

    assert_redirected_to new_user_session_path
  end

  test 'should create a new subscription' do
    sign_in users(:regular_user)

    assert_difference('Subscription.count') do
      post :create, params: { subscription: { frequency: 'weekly', subscribable_type: 'Event' }, q: 'fish', country: 'Finland' }
    end

    assert_equal 'fish', assigns(:subscription).query
    assert_equal ['country'], assigns(:subscription).facets.keys
    assert_equal 'Finland', assigns(:subscription).facets['country']

    assert_redirected_to subscriptions_path
  end

  test 'should not include junk params in new subscription' do
    sign_in users(:regular_user)

    assert_difference('Subscription.count') do
      post :create, params: { subscription: { frequency: 'weekly', subscribable_type: 'Event' }, q: 'fish', bananas: 14,
           country: 'Finland' }
    end

    assert_equal ['country'], assigns(:subscription).facets.keys

    assert_redirected_to subscriptions_path
  end

  test 'should delete a subscription' do
    sign_in users(:regular_user)
    sub = subscriptions(:daily_subscription)

    assert_difference('Subscription.count', - 1) do
      delete :destroy, params: { id: sub }
    end

    assert_redirected_to subscriptions_path
  end

  test "should not delete someone else's subscription" do
    sign_in users(:another_regular_user)
    sub = subscriptions(:daily_subscription)

    assert_no_difference('Subscription.count') do
      delete :destroy, params: { id: sub }
    end

    assert_response :forbidden
  end

  test 'should delete a subscription via unsubcribe link' do
    sub = subscriptions(:daily_subscription)

    assert_difference('Subscription.count', -1) do
      get :unsubscribe, params: { id: sub, code: sub.unsubscribe_code }
    end

    assert_response :success
  end

  test 'should not delete a subscription via unsubcribe link with invalid code' do
    sub = subscriptions(:daily_subscription)
    sub2 = subscriptions(:weekly_subscription)

    assert_no_difference('Subscription.count') do
      get :unsubscribe, params: { id: sub2, code: sub.unsubscribe_code }
    end

    assert_response :unprocessable_entity
  end
end
