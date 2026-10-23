require 'test_helper'

class GeocodingWorkerTest < ActiveSupport::TestCase
  test 'get coordinates for an event' do
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

  test 'get coordinates for an event from cache' do
    event = events(:kilburn)
    assert_nil event.latitude
    assert_nil event.longitude

    redis = Redis.new(url: TeSS::Config.redis_url)
    redis.set(event.address, [45, 45].to_json)

    Sidekiq::Testing.inline! do
      GeocodingWorker.perform_async([event.id, event.address])
    end

    event.reload
    assert_equal 45, event.latitude
    assert_equal 45, event.longitude
  end

  test 'set missing timezone from geocoded coordinates' do
    mock_nominatim

    event = events(:kilburn)
    event.update_columns(timezone: nil, start: Time.utc(2019, 11, 23, 10), end: Time.utc(2019, 11, 23, 16))

    Sidekiq::Testing.inline! do
      GeocodingWorker.perform_async([event.id, event.address])
    end

    assert_equal 'London', event.reload.timezone
  end

  test 'do not set timezone from geocoded coordinates for date-only event' do
    mock_nominatim

    event = events(:kilburn) # dates only, so given the default times when saved
    event.update_column(:timezone, nil)

    Sidekiq::Testing.inline! do
      GeocodingWorker.perform_async([event.id, event.address])
    end

    event.reload
    assert event.latitude.present?
    assert event.default_times?
    assert_nil event.timezone
  end

  test 'gracefully handle geocoding for event that no longer exists' do
    Sidekiq::Testing.inline! do
      assert_nothing_raised do
        GeocodingWorker.perform_async([Event.maximum(:id) + 1, 'Somewhere'])
      end
    end
  end
end
