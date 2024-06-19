require 'maxmind/db'

class Locator
  include Singleton

  def initialize
    if database_path.exist?
      @reader = MaxMind::DB.new(database_path, mode: MaxMind::DB::MODE_MEMORY)
    else
      warn "ERROR: No GeoIP database found at #{database_path}. Download from: https://dev.maxmind.com/geoip/geolite2-free-geolocation-data?lang=en"
    end
    @reader = database_path.exist? ? MaxMind::DB.new(database_path, mode: MaxMind::DB::MODE_MEMORY) : nil
  end

  def lookup(ip)
    @reader&.get(ip)
  end

  private

  # Don't distribute the database file - can be downloaded with a free account from:
  #  https://dev.maxmind.com/geoip/geolite2-free-geolocation-data?lang=en
  def database_path
    Rails.root.join('config', 'data', 'GeoLite2-Country.mmdb')
  end
end
