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
      unless locations.empty?
        puts "#{e.title} | #{locations.inspect}"
        location = locations.reject(&:blank?).join(',')
        latitude = nil
        longitude = nil

        if !seen.has_key?(location)
          result = Geocoder.search(location).first
          if result
            #puts "RESULT: #{result.latitude}, #{result.longitude}"
            seen[location] = [result.latitude, result.longitude]
            # Create edit suggestion here.
            latitude = result.latitude
            longitude = result.longitude
          end
          sleep(rand(9) + 1)
        else
          #puts "SEEN: #{seen[location][0]}, #{seen[location][1]}"
          # Or, create edit suggestion here.
          latitude = seen[location][0]
          longitude = seen[location][1]
        end

        next unless latitude && longitude

        suggestion = EditSuggestion.where(suggestible_type: 'Event', suggestible_id: e.id).first_or_create
        #puts "S1: #{suggestion.inspect}"
        suggestion.data_fields = {} if suggestion.data_fields.nil?
        suggestion.data_fields['geographic_coordinates'] = [latitude, longitude]
        suggestion.save!
        #puts "S2: #{suggestion.inspect}"

      end
    end
  end

end
