require 'geocoder'

namespace :tess do

  desc 'Update lat/lon for events'
  task update_lat_lon: :environment do
    Geocoder.configure(:lookup => :nominatim,
                       :http_headers => { 'User-Agent' => 'Elixir TeSS <tess-support@googlegroups.com>' }
                      )


    events = Event.where(:latitude => nil, :longitude => nil).where(["#{Event.table_name}.nominatim_count < ?", 3])

    puts "Found #{events.count} events to query with Nominatim"

    # Submit a worker for each matching event, one per minute.
    start_time = 1
    events[0,2].each do |e|
      locations = [
          e.city,
          e.county,
          e.country,
          e.postcode,
      ].select { |x| !x.nil? and x != '' }

      # Only proceed if there's at least one location field to look up.
      if locations.empty?
        # TODO: Mark this record to not be queried again, i.e. set the
        # TODO: nominatim_queries value to the maximum immediately.
        e.nominatim_count = 3
        e.save!
      else
        # TODO: submit event_id, and locations to worker.
        location = locations.reject(&:blank?).join(',')
        puts "Looking up: #{e.title}; #{location}"
        GeocodingWorker.perform_in(start_time.minute, [e.id, location])
        start_time += 1
      end
    end
  end

end
