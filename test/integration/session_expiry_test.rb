require 'test_helper'

class SessionExpiryTest < ActionDispatch::IntegrationTest
  test 'sets expire_after in production' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('production')) do
      TeSS::Config.stub(:login_expires_after, 3600) do
        load Rails.root.join('config/initializers/session_store.rb')
        assert_equal 3600, Rails.application.config.session_options[:expire_after]
      end
    end
  end

  test 'does not set expire_after outside production' do
    Rails.stub(:env, ActiveSupport::StringInquirer.new('test')) do
      TeSS::Config.stub(:login_expires_after, 3600) do
        load Rails.root.join('config/initializers/session_store.rb')
        assert_nil Rails.application.config.session_options[:expire_after]
      end
    end
  end
end
