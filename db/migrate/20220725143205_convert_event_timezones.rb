class ConvertEventTimezones < ActiveRecord::Migration[6.1]
  def up
    Event.where.not(timezone: ActiveSupport::TimeZone::MAPPING.keys + [nil, '']).find_each do |event|
      tz = mapping[event.timezone]
      event.update_column(:timezone, tz) if tz
    end
  end

  def down

  end

  private

  # Produce a mapping of time zone abbreviations (CEST, CET, GMT etc.) to Rails' time zone names.
  def mapping
    return @map if @map
    @map = {
      "CET" => "Amsterdam",
      "CEST" => "Amsterdam",
      "GMT" => "London",
      "BST" => "London"
    }

    ActiveSupport::TimeZone::MAPPING.each do |label, zone|
      tzinfo = TZInfo::Timezone.get(zone)
      # Pick two dates to get the DST and non-DST versions of the timezone.
      # These two dates should account for all the different DST boundaries across the world.
      winter = tzinfo.local_time(2020, 1, 1).strftime("%Z")
      summer = tzinfo.local_time(2020, 8, 1).strftime("%Z")
      @map[winter] ||= label unless winter =~ (/[-+]/)
      @map[summer] ||= label unless summer =~ (/[-+]/)
    end

    @map
  end
end
