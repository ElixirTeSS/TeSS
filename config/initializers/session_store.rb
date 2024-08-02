# Be sure to restart your server when you modify this file.
opts = Rails.env.production? ? { same_site: :strict, secure: true } : {}
Rails.application.config.session_store :cookie_store, **opts
