require 'test_helper'

class SubscriptionMailerTest < ActionMailer::TestCase
  setup do
    @routes = Rails.application.routes.url_helpers
    @url_opts = Rails.application.routes.default_url_options
    Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options
  end

  teardown do
    Rails.application.routes.default_url_options = @url_opts
  end

  test 'text digest' do
    sub = subscriptions(:weekly_subscription)
    m1 = materials(:good_material)
    m2 = materials(:bad_material)
    digest = MockSearchResults.new([m1, m2])
    email = SubscriptionMailer.digest(sub, digest)

    assert sub.user.receive_subscription_emails
    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [TeSS::Config.sender_email], email.from
    assert_equal [sub.user.email], email.to
    assert_equal "#{TeSS::Config.site['title_short']} weekly digest - 2 new materials matching your criteria",
                 email.subject
    body = email.text_part.body.to_s

    assert body.include?(m1.title), 'Expected first material title to appear in email body'
    assert body.include?(@routes.material_url(m1)), 'Expected first material URL to appear in email body'
    assert body.include?(m2.title), 'Expected second material title to appear in email body'
    assert body.include?(@routes.material_url(m2)), 'Expected second material URL to appear in email body'
    assert body.include?(@routes.unsubscribe_subscription_url(sub, code: sub.unsubscribe_code)), 'Expected unsubscribe link'
    assert body.include? 'Collections' # regular_user is owner of some collections
    assert body.include? collections(:one).title
    assert body.include? @routes.curate_materials_collection_url(collections(:one))
  end

  test 'text digest with collaborating collections' do
    # TODO: do not use fixture here but create new, so there are not so many collections
    sub = subscriptions(:weekly_subscription)
    m1 = materials(:good_material)
    m2 = materials(:bad_material)
    collaborating_collection = Collection.create!(title: 'collab', user: users(:admin))
    collaborating_collection.collaborators << users(:regular_user)
    digest = MockSearchResults.new([m1, m2])
    email = SubscriptionMailer.digest(sub, digest)

    assert_emails 1 do
      email.deliver_now
    end

    body = email.text_part.body.to_s
    assert body.include? 'Collections'
    assert body.include? collaborating_collection.title
    assert body.include? @routes.curate_materials_collection_url(collaborating_collection)
  end

  test 'html event digest' do
    sub = subscriptions(:event_subscription)
    e = [
      events(:one),
      events(:two),
      events(:month_long_event),
      events(:year_long_event)
    ]
    digest = MockSearchResults.new(e)
    email = SubscriptionMailer.digest(sub, digest)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [TeSS::Config.sender_email], email.from
    assert_equal [sub.user.email], email.to
    assert_equal "#{TeSS::Config.site['title_short']} weekly digest - #{e.length} new events matching your criteria", email.subject

    html = email.html_part.body.to_s

    e.each do |event|
      assert html.include?(@routes.event_url(event)), "Event URL was missing from email: #{@routes.event_url(event)}"
    end

    assert html.include?(@routes.unsubscribe_subscription_url(sub, code: sub.unsubscribe_code)), 'Expected unsubscribe link'
    assert_not html.include? 'Collections' # admin is not owner of some collections
  end

  test 'html digest with collaborating collections' do
    # TODO: do not use fixture here but create new, so there are not so many collections
    sub = subscriptions(:weekly_subscription)
    m1 = materials(:good_material)
    m2 = materials(:bad_material)
    collaborating_collection = Collection.create!(title: 'collab', user: users(:regular_user))
    collaborating_collection.collaborators << users(:admin)
    digest = MockSearchResults.new([m1, m2])
    email = SubscriptionMailer.digest(sub, digest)

    assert_emails 1 do
      email.deliver_now
    end

    html = email.html_part.body.to_s
    assert html.include? 'Collections' # regular_user is owner of some collections
    assert html.include? collections(:one).title
    assert html.include? @routes.curate_materials_collection_url(collaborating_collection)
  end

  test 'does not email if user opted out of subscription emails' do
    sub = subscriptions(:weekly_subscription)
    m1 = materials(:good_material)
    m2 = materials(:bad_material)
    digest = MockSearchResults.new([m1, m2])
    email = SubscriptionMailer.digest(sub, digest)
    user = sub.user
    user.receive_subscription_emails = false
    user.save!

    refute user.receive_subscription_emails
    assert_emails 0 do
      email.deliver_now
    end
  end
end
