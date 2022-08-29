require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TeSS
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.eager_load_paths << Rails.root.join('lib')

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :post, :options]
      end
    end

    config.tess = config_for(Rails.env.test? ? Pathname.new(Rails.root).join('test', 'config', 'test_tess.yml') : :tess)

    # locales
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', 'overrides', '**', '*.{rb,yml}')] unless Rails.env.test?
    config.i18n.available_locales = [:en]
    config.i18n.default_locale = :en

    # Workaround for https://stackoverflow.com/questions/72970170/upgrading-to-rails-6-1-6-1-causes-psychdisallowedclass-tried-to-load-unspecif
    config.active_record.use_yaml_unsafe_load
  end

  Config = OpenStruct.new(Rails.configuration.tess.with_indifferent_access)

  Config.redis_url = TeSS::Config.redis_url
end
