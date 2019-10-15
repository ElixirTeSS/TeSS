require 'test_helper'

class SubscriptionTest < ActiveSupport::TestCase

  test 'users can have subscriptions' do
    user = users(:another_regular_user)

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

  test 'can generate and verify unsubscribe code' do
    user = users(:regular_user)
    sub = user.subscriptions.create(frequency: :daily, subscribable_type: 'Event')
    sub2 = user.subscriptions.create(frequency: :weekly, subscribable_type: 'Event')

    assert sub.valid_unsubscribe_code?(sub.unsubscribe_code)
    assert sub2.valid_unsubscribe_code?(sub2.unsubscribe_code)
    refute sub.valid_unsubscribe_code?(sub2.unsubscribe_code)
    refute sub2.valid_unsubscribe_code?(sub.unsubscribe_code)
    refute sub.valid_unsubscribe_code?('meow')
  end

  test 'sets last_checked_at field on create' do
    user = users(:regular_user)
    sub = user.subscriptions.create(frequency: :daily, subscribable_type: 'Event')

    assert_not_nil sub.last_checked_at
  end

  test 'sets last_checked_at field on check' do
    sub = subscriptions(:daily_subscription)
    old_date = sub.last_checked_at

    sub.check

    assert_not_nil sub.last_checked_at
    assert_not_equal old_date, sub.last_checked_at
  end

  test 'can find all subscriptions that are due to be checked' do
    daily_sub = subscriptions(:daily_subscription)
    weekly_sub = subscriptions(:weekly_subscription)
    monthly_sub = subscriptions(:monthly_subscription)

    assert daily_sub.due?
    assert weekly_sub.due?
    assert monthly_sub.due?

    due = Subscription.due
    assert_includes due, daily_sub
    assert_includes due, weekly_sub
    assert_includes due, monthly_sub

    daily_sub.check
    weekly_sub.check

    refute daily_sub.due?
    refute weekly_sub.due?
    assert monthly_sub.due?

    due = Subscription.due
    assert_not_includes due, daily_sub
    assert_not_includes due, weekly_sub
    assert_includes due, monthly_sub
  end

  test '24-hour subscription is due slightly before 24 hours' do
    # To prevent "mis-alignment" with daily cronjob.
    sub = Subscription.new(frequency: :daily, user: users(:regular_user), query: 'test', subscribable_type: 'Material',
                           last_checked_at: 60.minutes.ago)
    sub.save!
    refute sub.due?

    sub.update_column(:last_checked_at, 21.hours.ago)
    refute sub.due?

    sub.update_column(:last_checked_at, (24.hours - 10.minutes).ago)
    assert sub.due?

    sub.update_column(:last_checked_at, (24.hours + 10.minutes).ago)
    assert sub.due?

    sub.update_column(:last_checked_at, 27.hours.ago)
    assert sub.due?
  end

  test 'processes subscription and sends email' do
    sub = subscriptions(:daily_subscription)

    assert_nil sub.last_sent_at

    # Mock the digest since we're not running solr
    mock_digest = MockSearchResults.new(materials(:good_material))
    sub.stub(:digest, mock_digest) do
      assert_difference 'ActionMailer::Base.deliveries.size', 1 do
        sub.process
      end
    end

    assert_not_nil sub.last_sent_at

    ActionMailer::Base.deliveries.clear
  end

  test 'does not send email if empty digest' do
    sub = subscriptions(:daily_subscription)

    assert_nil sub.last_sent_at

    mock_digest = MockSearchResults.new([])
    sub.stub(:digest, mock_digest) do
      assert_no_difference 'ActionMailer::Base.deliveries.size' do
        sub.process
      end
    end

    assert_nil sub.last_sent_at

    ActionMailer::Base.deliveries.clear
  end

  test 'facets with max age' do
    sub = subscriptions(:daily_subscription)
    assert_equal({ type: ['fruit', 'veg'], max_age: '24 hours' }.with_indifferent_access, sub.facets_with_max_age)

    sub = subscriptions(:monthly_subscription)
    assert_equal({ type: ['fruit', 'veg'], max_age: '1 month' }.with_indifferent_access, sub.facets_with_max_age)

    sub = subscriptions(:event_subscription)
    assert_equal({ times: ["good", "great"], max_age: '1 week' }.with_indifferent_access, sub.facets_with_max_age)
  end
end
