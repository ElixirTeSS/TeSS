# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
Rails.application.config.assets.precompile += %w( twitter/bootstrap/* fontawesome*)
Rails.application.config.assets.precompile += %w( jquery-ui/* )
Rails.application.config.assets.precompile += %w( rails_admin/rails_admin.css rails_admin/rails_admin.js )
Rails.application.config.assets.precompile += %w( favicon.png )
Rails.application.config.assets.precompile += %w( ELIXIR_TeSS_logo_white-80px-height.png )
Rails.application.config.assets.precompile += %w( placeholder-organization.png )
Rails.application.config.assets.precompile += %w( placeholder-group.png )
Rails.application.config.assets.precompile += %w( placeholder-group.png )
Rails.application.config.assets.precompile += %w( ELIXIR_UK_logo_orange.png )
Rails.application.config.assets.precompile += %w( manchester_logo.png )
Rails.application.config.assets.precompile += %w( oxford_logo.jpg )
Rails.application.config.assets.precompile += %w( training-and-development.jpg )
Rails.application.config.assets.precompile += %w( materials.jpg )
Rails.application.config.assets.precompile += %w( events.jpg )
Rails.application.config.assets.precompile += %w( packages.jpg )
Rails.application.config.assets.precompile += %w( providers-6.jpg )
Rails.application.config.assets.precompile += %w( workflows.png )
Rails.application.config.assets.precompile += %w( workflow.png )
