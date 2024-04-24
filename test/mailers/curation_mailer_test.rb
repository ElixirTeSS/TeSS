require 'test_helper'

class CurationMailerTest < ActionMailer::TestCase
  setup do
    @routes = Rails.application.routes.url_helpers
    @url_opts = Rails.application.routes.default_url_options
    Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options
    @user = users(:unverified_user)
    @material = @user.materials.create!(title: 'Unverified Material',
                                        url: 'http://example.com/shady-event',
                                        description: '123',
                                        licence: 'Fair',
                                        doi: 'https://doi.org/10.1200/RSE.2020.123',
                                        keywords: %w[unverified user material],
                                        contact: 'main contact',
                                        status: 'active')
    # Avoids queued emails affecting `assert_email` counts. See: https://github.com/ElixirTeSS/TeSS/issues/719
    perform_enqueued_jobs
  end

  teardown do
    Rails.application.routes.default_url_options = @url_opts
  end

  test 'text user approval' do
    email = CurationMailer.user_requires_approval(@user)

    assert_emails 1 do
      email.deliver_now
    end

    admin_emails = User.with_role('admin').map(&:email)

    assert_equal [TeSS::Config.sender_email], email.from
    assert_equal admin_emails, email.to
    assert_equal "#{TeSS::Config.site['title_short']} user \"#{@user.name}\" requires approval", email.subject

    body = email.text_part.body.to_s

    assert body.include?(@material.title), 'Expected material title to appear in email body'
    assert body.include?(@routes.material_url(@material)), 'Expected TeSS material URL to appear in email body'
    assert body.include?(@material.url), 'Expected material URL to appear in email body'

    assert body.include?(@routes.curate_users_url), 'Expected curation link'
  end

  test 'html user approval' do
    email = CurationMailer.user_requires_approval(@user)

    assert_emails 1 do
      email.deliver_now
    end

    admin_emails = User.with_role('admin').map(&:email)

    assert_equal [TeSS::Config.sender_email], email.from
    assert_equal admin_emails, email.to
    assert_equal "#{TeSS::Config.site['title_short']} user \"#{@user.name}\" requires approval", email.subject

    html = email.html_part.body.to_s

    assert html.include?(@material.title), 'Expected material title to appear in email body'
    assert html.include?(@routes.material_url(@material)), 'Expected TeSS material URL to appear in email body'
    assert html.include?(@material.url), 'Expected material URL to appear in email body'

    assert html.include?(@routes.curate_users_url), 'Expected curation link'
  end

  test 'can set mailer headers in config' do
    with_settings(mailer: { headers: { 'Sender': 'mail.sender@example.com', 'X-Something': 'yes' } }) do
      email = CurationMailer.user_requires_approval(@user)

      email_headers = {}
      email.header.fields.each { |f| email_headers[f.name] = f.value }

      assert_equal 'no-reply@example.com', email_headers['From']
      assert_equal 'mail.sender@example.com', email_headers['Sender']
      assert_equal 'yes', email_headers['X-Something']
    end
  end

  test 'text events approval' do
    @content_provider = content_providers(:goblet)
    @events = [events(:one), events(:scraper_user_event)]
    email = CurationMailer.events_require_approval(@content_provider, @events.pluck(:created_at).min - 1.week)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [TeSS::Config.sender_email], email.from
    assert_equal [@content_provider.contact], email.to
    assert_equal "#{TeSS::Config.site['title_short']} events require approval", email.subject

    text_body = email.text_part.body.to_s
    html_body = email.html_part.body.to_s

    [text_body, html_body].each do |body|
      @events.each do |event|
        assert body.include?(event.title)
        assert body.include?(event.description)
        assert body.include?(event.start.to_s)
        assert body.include?(event.end.to_s)
        assert body.include?(event.venue)
        assert body.include?(event.visible.to_s)
      end
    end
  end
end
