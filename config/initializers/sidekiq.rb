Sidekiq.configure_server do |config|
  config.redis = { url: TeSS::Config.redis_url }
end

Sidekiq.configure_client do |config|
  config.redis = { url: TeSS::Config.redis_url }
end
