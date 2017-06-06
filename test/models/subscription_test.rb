require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase

  test 'users can have subscriptions' do
    user = users(:regular_user)

    assert_equal 0, user.subscriptions.count

    sub = user.subscriptions.build(frequency: :daily, subscribable_type: 'Event',
                                   query: 'apples',
                                   facets: { categories: ['fruit', 'vegetables'] })

    assert_difference('Subscription.count') do
      sub.save
    end

    assert_equal 1, user.subscriptions.count
    sub = Subscription.last
    assert_equal 'apples', sub.query
    assert_includes sub.facets['categories'], 'fruit'
    assert_includes sub.facets['categories'], 'vegetables'
  end

  test 'can get and set frequency' do
    user = users(:regular_user)

    sub = user.subscriptions.build(frequency: :daily, subscribable_type: 'Event')
    assert_equal :daily, sub.frequency
    assert sub.valid?

    sub = user.subscriptions.build(frequency: 'weekly', subscribable_type: 'Event')
    assert_equal :weekly, sub.frequency
    assert sub.valid?

    sub = user.subscriptions.build(frequency: 'qwerty', subscribable_type: 'Event')
    assert_nil sub.frequency
    refute sub.valid?
    assert sub.errors.keys.include?(:frequency)
  end

  test 'validates subscribable type' do
    user = users(:regular_user)

    sub = user.subscriptions.build(frequency: :daily, subscribable_type: 'Event')
    assert sub.valid?

    sub = user.subscriptions.build(frequency: :daily, subscribable_type: 'Role')
    refute sub.valid?
    assert sub.errors.keys.include?(:subscribable_type)

    sub = user.subscriptions.build(frequency: :daily)
    refute sub.valid?
    assert sub.errors.keys.include?(:subscribable_type)
  end

end
