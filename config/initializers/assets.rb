# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = "1.0"

# Add node_modules subdirectories to the Sprockets asset load path so that
# JS/CSS packages installed via yarn can be referenced with //= require and @import.
%w[
  clipboard/dist
  devbridge-autocomplete/dist
  eonasdan-bootstrap-datetimepicker/src/js
  eonasdan-bootstrap-datetimepicker/build/css
  markdown-it/dist
  moment
  select2/dist/js
  select2/dist/css
].each do |path|
  Rails.application.config.assets.paths << Rails.root.join("node_modules/#{path}")
end

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w[ admin.js admin.css ]
