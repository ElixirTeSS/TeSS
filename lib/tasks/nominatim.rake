require 'geocoder'

namespace :tess do

  desc 'Update lat/lon for events'
  task update_lat_lon: :environment do
    Geocoder.configure(:lookup => :nominatim)

    seen = {}

    puts Event.where(:latitude => nil, :longitude => nil).count
    Event.where(:latitude => nil, :longitude => nil).each do |e|
      locations = [
          #e.venue,
          e.city,
          e.county,
          e.country,
          e.postcode,
      ].select { |x| !x.nil? and x != '' }
      if locations.length > 0
        puts "#{e.title} | #{locations.inspect}"
        location = locations.reject(&:blank?).join(',')
        if !seen.has_key?(location)
          result = Geocoder.search(location).first
          if result
            puts "RESULT: #{result.latitude}, #{result.longitude}"
            seen[location] = [result.latitude, result.longitude]
            # Create edit suggestion here.
          end
          sleep(rand(9) + 1)
        else
          puts "SEEN: #{seen[location][0]}, #{seen[location][1]}"
          # Or, create edit suggestion here.
        end
      end
    end
  end

end
