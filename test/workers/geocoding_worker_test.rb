require 'test_helper'
require 'sidekiq/testing'

class GeocodingWorkerTest < ActiveSupport::TestCase

  setup do
  end

  test 'Get coordinates for an event' do
    mock_nominatim

    event = events(:kilburn)
    assert_nil event.latitude
    assert_nil event.longitude

    Sidekiq::Testing.inline! do
      GeocodingWorker.perform_async([event.id, event.address])
    end

    event.reload
    assert_equal 53.14375, event.latitude.to_f.round(5)
    assert_equal 0.34290, event.longitude.to_f.round(5)
  end

  test 'Get coordinates for an event from cache' do
    event = events(:kilburn)
    assert_nil event.latitude
    assert_nil event.longitude

    redis = Redis.new
    redis.set(event.address, [45, 45].to_json)

    Sidekiq::Testing.inline! do
      GeocodingWorker.perform_async([event.id, event.address])
    end

    event.reload
    assert_equal 45, event.latitude
    assert_equal 45, event.longitude
  end
end
