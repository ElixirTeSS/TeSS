# frozen_string_literal: true

require 'test_helper'

class ConfigTest < ActiveSupport::TestCase
  test 'should load test secrets' do
    assert_equal 'test', Rails.application.secrets.oidc[:client_id]
  end

  test 'should load test TeSS config' do
    assert_equal 'test@example.com', TeSS::Config.contact_email
  end

  test 'site title should not be nil' do
    refute_nil TeSS::Config.site['title']
    assert_equal 'TeSS Test Instance', TeSS::Config.site['title']
  end

  test 'site title short should not be nil' do
    refute_nil TeSS::Config.site['title_short']
    assert_equal 'TTI', TeSS::Config.site['title_short']
  end

  test 'redis URL should be set' do
    assert_equal 'redis://127.0.0.1:6379/0', TeSS::Config.redis_url
  end
end
