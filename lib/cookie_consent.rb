# frozen_string_literal: true

class CookieConsent
  OPTIONS = %w[necessary tracking].freeze

  def initialize(store)
    @store = store
  end

  def options=(opts)
    opts = opts.split(',').map(&:strip)
    @store[:cookie_consent] = opts.join(',') unless opts.any? { |opt| OPTIONS.exclude?(opt) }
  end

  def options
    (@store[:cookie_consent] || '').split(',').select { |opt| OPTIONS.include?(opt) }
  end

  def revoke
    @store[:cookie_consent] = nil
  end

  def required?
    TeSS::Config.require_cookie_consent
  end

  def given?
    options.any?
  end

  def show_banner?
    required? && !given?
  end

  def allow_tracking?
    !required? || options.include?('tracking')
  end

  def allow_necessary?
    !required? || options.include?('necessary')
  end
end
