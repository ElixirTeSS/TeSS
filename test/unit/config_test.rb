require 'test_helper'

class ConfigTest < ActiveSupport::TestCase

  test 'should load test secrets' do
    assert_equal 'test', Rails.application.secrets.elixir_aai[:client_id]
  end

  test 'should load test TeSS config' do
    assert_equal 'test@example.com', TeSS::Config.contact_email
  end

end
