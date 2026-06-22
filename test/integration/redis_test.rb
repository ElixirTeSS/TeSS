require 'test_helper'

class RedisTest < ActionDispatch::IntegrationTest
  test 'checks redis is working' do
    redis = Redis.new(url: TeSS::Config.redis_url)

    redis.set('test123xyz', 'hello')

    assert_equal 'hello', redis.get('test123xyz')
  end
end
