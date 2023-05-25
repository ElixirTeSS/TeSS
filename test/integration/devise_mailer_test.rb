# frozen_string_literal: true

require 'test_helper'

class DeviseMailerTest < ActionDispatch::IntegrationTest
  setup do
    @routes = Rails.application.routes.url_helpers
    @url_opts = Rails.application.routes.default_url_options
    Rails.application.routes.default_url_options = Rails.application.config.action_mailer.default_url_options
  end

  teardown do
    Rails.application.routes.default_url_options = @url_opts
  end

  test 'mailer headers are applied to emails from devise' do
    assert_emails 1 do
      with_settings(force_user_confirmation: true,
                    mailer: { headers: { Sender: 'mail.sender@example.com', 'X-Something': 'yes' } }) do
        post users_path, params: {
          user: {
            username: 'mileyfan1997',
            email: 'h4nn4hm0nt4n4@example.com',
            password: '12345678',
            password_confirmation: '12345678',
            processing_consent: '1'
          }
        }
      end
    end

    email = ActionMailer::Base.deliveries.last
    email_headers = {}
    email.header.fields.each { |f| email_headers[f.name] = f.value }

    assert_equal 'no-reply@example.com', email_headers['From']
    assert_equal 'mail.sender@example.com', email_headers['Sender']
    assert_equal 'yes', email_headers['X-Something']
  end
end
