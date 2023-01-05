# frozen_string_literal: true

# Check a timezone field against known keys, and have a fuzzy finder for it
module WithTimezone
  extend ActiveSupport::Concern

  included do
    before_validation :check_timezone # set to standard key

    validates :timezone, inclusion: { in: ActiveSupport::TimeZone::MAPPING.keys,
                                      message: 'not found and cannot be linked to a valid timezone',
                                      allow_blank: true }
  end

  private

  def check_timezone
    begin
      tz_key = find_timezone_key timezone
      self.timezone = tz_key unless tz_key.nil? || tz_key == timezone
    rescue StandardError
      # ignore error
    end
    nil
  end

  def find_timezone_key(name)
    return name if name.nil?

    # check name vs ActiveSupport
    timezones = ActiveSupport::TimeZone::MAPPING
    return name if timezones.keys.include? name
    return timezones.key(name) unless timezones.key(name).nil?

    # check for linked zones in TZInfo
    tzinfo = TZInfo::Timezone.get(name)
    if tzinfo.nil? && tzinfo.is_a?(TZInfo::LinkedTimezone)
      # repeat search with canonical timezone identifier
      return find_timezone_key tzinfo.canonical_zone.identifier
    end

    # otherwise
    nil
  end
end
