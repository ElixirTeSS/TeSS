require 'redis'
require 'json'

# This worker is to be called by the nominatim.rake task so that lookups are queued rather than being
# run all at once and thereby triggering rate limits.
# Redis is used to share location strings between workers so that they don't query the same one multiple
# times, e.g. if there are several events taking place at the same venue.

class GeocodingWorker
  include Sidekiq::Worker

  def perform(arg_array)
    event_id, location = arg_array
    event = Event.find(event_id)

    redis = Redis.new

    if redis.exists(location)
      puts "Re-using: #{location}"
      event.geocoding_cache_lookup
    else
      puts "New location: #{location}"
      event.geocoding_api_lookup
    end

    event.save!
  end

end

