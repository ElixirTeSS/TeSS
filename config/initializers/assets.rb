# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.scss, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.compile = true
Rails.application.config.assets.precompile =  ['*.js', '*.css', '*.css.erb']
#Rails.application.config.assets.precompile += [ 'fontawesome-webfont.*' ]
Rails.application.config.assets.precompile += %w( twitter/bootstrap/* fontawesome*)
Rails.application.config.assets.precompile += %w( jquery-ui/* )
Rails.application.config.assets.precompile += %w( rails_admin/* )
Rails.application.config.assets.precompile += %w( favicon.png )
Rails.application.config.assets.precompile += %w( ELIXIR_TeSS_logo_white-80px-height.png )
Rails.application.config.assets.precompile += %w( placeholder-organization.png )
Rails.application.config.assets.precompile += %w( placeholder-group.png )
