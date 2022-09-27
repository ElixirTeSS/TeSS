require 'geocoder'

Geocoder.configure(lookup: :nominatim,
                   http_headers: { 'User-Agent' => "ELIXIR TeSS <#{TeSS::Config.contact_email}>" })
