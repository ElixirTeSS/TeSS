require 'redis'

namespace :tess do

  desc 'Update lat/lon for events'
  task update_lat_lon: :environment do
    events = Event.where(:latitude => nil, :longitude => nil).where(["#{Event.table_name}.nominatim_count < ?", Event::NOMINATIM_MAX_ATTEMPTS])

    puts "Found #{events.count} events to query with Nominatim"

    # Submit a worker for each matching event, one per minute.
    events.each do |e|
      puts "Enqueuing: #{e}"
    end
    events.each(&:enqueue_geocoding_worker)
  end

end
