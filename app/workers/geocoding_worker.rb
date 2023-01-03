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
    #puts "GeocodingWorker.perform(#{event_id.to_s},#{location.to_s})"

    event = Event.find_by_id(event_id)
    unless event
      logger.debug "Event #{event_id} not found"
      return
    end

    Redis.exists_returns_integer = true
    redis = Redis.new(url: TeSS::Config.redis_url)

    if redis.exists?(location)
      event.geocoding_cache_lookup
    else
      event.geocoding_api_lookup
    end

    event.save!
  end

  #def self.perform_async(i)
   # code here
  #end

end

