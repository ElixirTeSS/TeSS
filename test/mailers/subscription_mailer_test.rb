# frozen_string_literal: true

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

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [TeSS::Config.sender_email], email.from
    assert_equal [sub.user.email], email.to
    assert_equal "#{TeSS::Config.site['title_short']} weekly digest - 2 new materials matching your criteria",
                 email.subject
    body = email.text_part.body.to_s

    assert_includes body, m1.title, 'Expected first material title to appear in email body'
    assert_includes body, @routes.material_url(m1), 'Expected first material URL to appear in email body'
    assert_includes body, m2.title, 'Expected second material title to appear in email body'
    assert_includes body, @routes.material_url(m2), 'Expected second material URL to appear in email body'
    assert_includes body, @routes.unsubscribe_subscription_url(sub, code: sub.unsubscribe_code),
                    'Expected unsubscribe link'
    assert_includes body, 'Collections' # regular_user is owner of some collections
    assert_includes body, collections(:one).title
    assert_includes body, @routes.curate_materials_collection_url(collections(:one))
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

    assert_includes body, 'Collections'
    assert_includes body, collaborating_collection.title
    assert_includes body, @routes.curate_materials_collection_url(collaborating_collection)
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
    assert_equal "#{TeSS::Config.site['title_short']} weekly digest - #{e.length} new events matching your criteria",
                 email.subject

    html = email.html_part.body.to_s

    e.each do |event|
      assert_includes html, @routes.event_url(event), "Event URL was missing from email: #{@routes.event_url(event)}"
    end

    assert_includes html, @routes.unsubscribe_subscription_url(sub, code: sub.unsubscribe_code),
                    'Expected unsubscribe link'
    refute_includes html, 'Collections' # admin is not owner of some collections
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

    assert_includes html, 'Collections' # regular_user is owner of some collections
    assert_includes html, collections(:one).title
    assert_includes html, @routes.curate_materials_collection_url(collaborating_collection)
  end
end
