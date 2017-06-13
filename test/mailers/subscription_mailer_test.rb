require 'test_helper'

class SubscriptionMailerTest < ActionMailer::TestCase

  # FB: Need to do the following for full URL helpers to work properly
  include Rails.application.routes.url_helpers

  setup do
    @url_opts = Rails.application.routes.default_url_options
    Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options
  end

  teardown do
    Rails.application.routes.default_url_options = @url_opts
  end

  test 'digest' do
    sub = subscriptions(:weekly_subscription)
    m1 = materials(:good_material)
    m2 = materials(:bad_material)
    digest = MockDigest.new([m1, m2])
    email = SubscriptionMailer.digest(sub, digest)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [TeSS::Config.contact_email], email.from
    assert_equal [sub.user.email], email.to
    assert_equal 'TeSS weekly digest - 2 new materials matching your criteria', email.subject
    body = email.text_part.body.to_s

    assert body.include?(m1.title), 'Expected first material title to appear in email body'
    assert body.include?(material_url(m1)), 'Expected first material URL to appear in email body'
    assert body.include?(m2.title), 'Expected second material title to appear in email body'
    assert body.include?(material_url(m2)), 'Expected second material URL to appear in email body'
    assert body.include?(unsubscribe_subscription_url(sub, code: sub.unsubscribe_code)), 'Expected unsubscribe link'
  end
end
