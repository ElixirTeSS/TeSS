class CookieConsent
  LEVELS = %w(all necessary).freeze

  def self.required?
    TeSS::Config.require_cookie_consent
  end

  def initialize(store)
    @store = store
  end

  def level= lvl
    lvl = lvl.strip.downcase
    @store[:cookie_consent] = lvl if LEVELS.include?(lvl)
  end

  def level
    lvl = @store[:cookie_consent]
    return nil unless LEVELS.include?(lvl)
    lvl
  end

  def required?
    self.class.required?
  end

  def given?
    !required? || level.present?
  end

  def allow_all?
    !required? || level == 'all'
  end

  def allow_tracking?
    !required? || allow_all?
  end

  def allow_necessary?
    !required? || allow_all? || level == 'necessary'
  end
end