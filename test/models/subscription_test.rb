require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase

  test 'users can have subscriptions' do
    user = users(:regular_user)

    assert_equal 0, user.subscriptions.count

    sub = user.subscriptions.build(frequency: :daily)

    assert_difference('Subscription.count') do
      sub.save
    end

    assert_equal 1, user.subscriptions.count
  end

  test 'can get and set frequency' do
    user = users(:regular_user)

    sub = user.subscriptions.build(frequency: :daily)
    assert_equal :daily, sub.frequency
    sub.valid?

    sub = user.subscriptions.build(frequency: 'weekly')
    assert_equal :weekly, sub.frequency
    assert sub.valid?

    sub = user.subscriptions.build(frequency: 'qwerty')
    assert_nil sub.frequency
    refute sub.valid?
  end

end
