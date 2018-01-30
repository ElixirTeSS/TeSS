require 'geocoder'

Geocoder.configure(lookup: :nominatim,
                   http_headers: { 'User-Agent' => "Elixir TeSS <#{TeSS::Config.contact_email}>" })
