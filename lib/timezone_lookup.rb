# Finds the time zone of a place, as one of the time zone names TeSS accepts (the keys of
# ActiveSupport::TimeZone::MAPPING, e.g. "Eastern Time (US & Canada)").
#
# Coordinates are looked up offline in the timezone-boundary-builder polygons bundled with the wheretz gem. Without
# coordinates, a country with a single time zone gives that zone.
module TimezoneLookup
  # Sample times over a year, to compare the UTC offsets (including daylight saving time) of two time zones
  SAMPLES = (0..23).map { |i| Time.utc(Time.now.year, 1, 1) + (i * 365.25 / 24).days }.freeze

  # Returns a TeSS time zone name, or nil if none can be found.
  def self.find(latitude: nil, longitude: nil, country: nil)
    if latitude.present? && longitude.present?
      zone = zone_at(latitude.to_f, longitude.to_f)
      return rails_name(zone, latitude.to_f, longitude.to_f) if zone
    end

    zone = country_zone(country)
    rails_name(zone) if zone
  end

  # Whether two TeSS time zone names (or IANA identifiers) have the same UTC offsets over the year, e.g. "London"
  # and "Edinburgh". False if either is unknown.
  def self.same_offsets?(zone_a, zone_b)
    ids = [zone_a, zone_b].map { |zone| ActiveSupport::TimeZone[zone.to_s]&.tzinfo&.identifier }
    return false if ids.any?(&:nil?)

    offsets(ids[0]) == offsets(ids[1])
  end

  # The IANA time zone at a point, or nil if there is none or the point is on a border between time zones.
  def self.zone_at(latitude, longitude)
    zone = WhereTZ.lookup(latitude, longitude)
    zone.is_a?(String) ? zone : nil
  rescue ArgumentError
    nil
  end

  # The main IANA time zone of a country (name or ISO 3166 code), if all its time zones have the same UTC offsets
  # (e.g. Germany's Europe/Berlin and Europe/Busingen).
  def self.country_zone(country)
    return nil if country.blank?

    iso = ISO3166::Country[country] || ISO3166::Country.find_country_by_any_name(country)
    return nil unless iso

    zones = TZInfo::Country.get(iso.alpha2).zone_identifiers
    zones.first if zones.map { |zone| offsets(zone) }.uniq.one?
  rescue TZInfo::InvalidCountryCode
    nil
  end

  # The Rails time zone name for an IANA time zone: its own name if Rails has one, otherwise the Rails time zone
  # with the same UTC offsets over the year that is nearest to the given point (or to the zone's main city).
  def self.rails_name(zone, latitude = nil, longitude = nil)
    canonical = TZInfo::Timezone.get(zone).canonical_identifier
    mapping = ActiveSupport::TimeZone::MAPPING
    name = [zone, canonical].lazy.map { |id| mapping.key?(id) ? id : named_after_city(id) }.find(&:itself)
    return name if name

    offsets = offsets(canonical)
    candidates = mapping.select { |_, id| offsets(id) == offsets }.keys
    latitude, longitude = locations[canonical] if latitude.nil? || longitude.nil?
    return candidates.first if latitude.nil? || longitude.nil?

    candidates.min_by do |candidate|
      location = locations[TZInfo::Timezone.get(mapping[candidate]).canonical_identifier]
      location ? distance(latitude, longitude, *location) : Float::INFINITY
    end
  rescue TZInfo::InvalidTimezoneIdentifier
    nil
  end

  # The Rails name for an IANA time zone, preferring the one named after its city when there are several
  # (e.g. "London" rather than "Edinburgh" for Europe/London).
  def self.named_after_city(zone)
    names = ActiveSupport::TimeZone::MAPPING.select { |_, id| id == zone }.keys
    city = zone.split('/').last.tr('_', ' ')
    names.find { |name| name == city } || names.first
  end

  def self.offsets(zone)
    @offsets ||= {}
    @offsets[zone] ||= begin
      tz = TZInfo::Timezone.get(zone)
      SAMPLES.map { |time| tz.period_for_utc(time).observed_utc_offset }
    end
  end

  # The location of the main city of each IANA time zone, from tzinfo's zone.tab
  def self.locations
    @locations ||= TZInfo::Country.all.flat_map(&:zone_info).to_h do |zone|
      [zone.identifier, [zone.latitude.to_f, zone.longitude.to_f]]
    end
  end

  # Angle between two points on a sphere (relative distance is all that is needed)
  def self.distance(lat1, lon1, lat2, lon2)
    rad = Math::PI / 180
    cos = (Math.sin(lat1 * rad) * Math.sin(lat2 * rad)) +
          (Math.cos(lat1 * rad) * Math.cos(lat2 * rad) * Math.cos((lon1 - lon2) * rad))
    Math.acos(cos.clamp(-1, 1))
  end
end
