require 'sidekiq-status'

Sidekiq.configure_server do |config|
  config.redis = { url: TeSS::Config.redis_url }
  Sidekiq::Status.configure_server_middleware config, expiration: 30.minutes.to_i

  Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes.to_i
end

Sidekiq.configure_client do |config|
  config.redis = { url: TeSS::Config.redis_url }
  Sidekiq::Status.configure_client_middleware config, expiration: 30.minutes.to_i
end
