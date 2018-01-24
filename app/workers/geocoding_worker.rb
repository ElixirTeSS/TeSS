require 'geocoder'
require 'redis'
require 'json'

# This worker is to be called by the nominatim.rake task so that lookups are queued rather than being
# run all at once and thereby triggering rate limits.
# Redis is used to share location strings between workers so that they don't query the same one multiple
# times, e.g. if there are several events taking place at the same venue.

class GeocodingWorker
  include Sidekiq::Worker
  Geocoder.configure(:lookup => :nominatim,
                     :http_headers => { 'User-Agent' => 'Elixir TeSS <tess-support@googlegroups.com>' }
                    )

  def perform(arg_array)
    event_id, location = arg_array
    event = Event.find(event_id)
    return unless event
    redis = Redis.new

    latitude = nil
    longitude = nil

    if redis.get location
      event.latitude, event.longitude = JSON.parse(redis.get(location))
      puts "Re-using: #{location}"
    else
      puts "New location: #{location}"
      result = Geocoder.search(location).first
      if result
        event.latitude = result.latitude
        event.longitude = result.longitude
        redis.set location, [event.latitude, event.longitude].to_json
      end
      event.nominatim_count += 1
    end

    event.save!

  end

end

__END__
[2785, "Heverlee,Belgium,3001"]
[8, "Leuven,Belgium,3010"]
