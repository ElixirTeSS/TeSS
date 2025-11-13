# Be sure to restart your server when you modify this file.
opts = {}

if Rails.env.production?
  opts = { same_site: :lax, secure: true }
  expiry_time = TeSS::Config.login_expires_after
  opts[:expire_after] = expiry_time unless expiry_time.nil?
end

Rails.application.config.session_store :cookie_store, **opts
