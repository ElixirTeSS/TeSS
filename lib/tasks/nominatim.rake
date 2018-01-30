require 'redis'

namespace :tess do

  desc 'Update lat/lon for events'
  task update_lat_lon: :environment do
    events = Event.where(:latitude => nil, :longitude => nil).where(["#{Event.table_name}.nominatim_count < ?", 3])

    puts "Found #{events.count} events to query with Nominatim"

    redis = Redis.new

    # Submit a worker for each matching event, one per minute.
    start_time = 1
    events.each do |e|
      locations = e.address
      # Only proceed if there's at least one location field to look up.
      if locations.empty?
        # Mark this record to not be queried again, i.e. set the
        # nominatim_queries value to the maximum immediately.
        e.nominatim_count = 3
        e.save!
      else
        # submit event_id, and locations to worker.
        location = locations.reject(&:blank?).join(',')
        puts "Looking up: #{e.title}; #{location}"
        time = Time.now.to_i + start_time.minute
        redis.set 'last_geocode', time
        #GeocodingWorker.perform_at(time, [e.id, location])
        start_time += 1
      end
    end
  end

end
