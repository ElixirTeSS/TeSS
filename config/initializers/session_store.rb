require 'ipaddr'
require 'public_suffix'

# Be sure to restart your server when you modify this file.
opts = {
  domain: lambda do |request|
    host = request&.host.to_s.strip.downcase

    next nil if host.blank? || !host.include?('.')

    begin
      IPAddr.new(host)
      next nil
    rescue IPAddr::InvalidAddressError
      nil
    end

    begin
      PublicSuffix.domain(host)
    rescue PublicSuffix::Error
      nil
    end
  end
}

if Rails.env.production?
  opts.merge!(same_site: :lax, secure: true)
  expiry_time = TeSS::Config.login_expires_after
  opts[:expire_after] = expiry_time unless expiry_time.blank?
end

Rails.application.config.session_store :cookie_store, **opts
