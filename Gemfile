# frozen_string_literal: true

source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.0'

gem 'bootsnap', '>= 1.4.4', require: false

# Use postgresql as the database for Active Record
gem 'pg'

# For installing PG on macs:
gem 'lunchy'

# Use SCSS for stylesheets
gem 'sassc-rails', '~> 2.1.2'
gem 'sass-rails', '~> 5.0'

# Use Terser as compressor for JavaScript assets
gem 'terser'

# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer'#, platforms: :ruby

# CRUD of resources via a UI
gem 'haml'
gem 'rails_admin', '~> 2.2.1'

# Authentication
gem 'devise'
gem 'devise_invitable', '~> 2.0.5'
gem 'omniauth_openid_connect'
gem 'omniauth-rails_csrf_protection'

# Activity logging
gem 'public_activity', '~> 1.6.4'

gem 'simple_token_authentication', '~> 1.0'

gem 'bootstrap-sass', '>= 3.4.1'

gem 'font-awesome-sass', '~> 4.7.0'

gem 'friendly_id', '~> 5.2.4'

# gem 'sunspot_rails', '~> 2.5.0'
gem 'sunspot_rails', github: 'sunspot/sunspot', branch: 'master'

gem 'progress_bar', '~> 1.1.0'

gem 'activerecord-session_store'

gem 'gravtastic', '~> 3.2.6'

gem 'dynamic_sitemaps', github: 'lassebunk/dynamic_sitemaps', branch: 'master'

gem 'whenever', '~> 1.0.0'

# These are required for Sidekiq, to look up scientific topics
gem 'httparty'
gem 'sidekiq', '~> 6.4.0'
gem 'sidekiq-status'
gem 'slim'

# Use jquery as the JavaScript library
gem 'jquery-qtip2-wrapper-rails'
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'jquery-turbolinks'
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.

group :doc do
  gem 'json', '>= 2.3.0'
  gem 'rdoc', '>= 6.3.1'
  gem 'sdoc', '>= 1.1.0'
end

# Gem for creating before_validation callbacks for stripping whitespace
gem 'auto_strip_attributes', '~> 2.0'

# Gem for validating URLs
gem 'validate_url', '~> 1.0.2'

# Gem for simple form: https://github.com/heartcombo/simple_form
gem 'country_select', '<= 4.0.0'
gem 'simple_form'

# Gem for rendering Markdown
gem 'redcarpet', '~> 3.5.1'

# Gem for paginating search results
gem 'will_paginate'
# gem 'will_paginate-bootstrap', '~> 1.0.1'

# Gem for authorisation
gem 'pundit', '~> 1.1.0'

# Simple colour picker from a predefined list
gem 'jquery-simplecolorpicker-rails'

# For getting date of materials for the home page
gem 'by_star', git: 'https://github.com/radar/by_star'

gem 'handlebars_assets'

gem 'kt-paperclip', '~> 7.0.0'

gem 'icalendar', '~> 2.4.1'

gem 'rss'

gem 'bootstrap-datepicker-rails', '~> 1.6.4.1'

gem 'rack-cors', require: 'rack/cors'

gem 'recaptcha', require: 'recaptcha/rails'

gem 'linkeddata'

gem 'sitemap-parser', '~> 0.5.6'
gem 'tess_rdf_extractors', git: 'https://github.com/ElixirTeSS/TeSS_RDF_Extractors'

# Used for lat/lon rake task
gem 'geocoder'
gem 'redis', '< 5.0.0'

# set serializers version
gem 'active_model_serializers', '~> 0.10.13'

gem 'private_address_check'

# For the link monitor rake taks
gem 'time_diff'

# For internationalisation (i18n)
gem 'i18n_data'
gem 'rails-i18n'

# for timezone information
gem 'tzinfo'
gem 'tzinfo-data'

# for currency information
gem 'money-rails'

# for iso country codes
gem 'iso_country_codes'

# for rest client
gem 'rest-client'

# for converting html to markdown
gem 'reverse_markdown'

# eventbrite api
gem 'eventbrite_sdk'

source 'https://rails-assets.org' do
  gem 'rails-assets-clipboard', '~> 1.5.12'
  gem 'rails-assets-devbridge-autocomplete', '~> 1.4.9'
  gem 'rails-assets-eonasdan-bootstrap-datetimepicker', '~> 4.17.42'
  gem 'rails-assets-markdown-it', '~> 7.0.1'
  gem 'rails-assets-moment', '~> 2.15.0'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'brakeman'
  gem 'bundler-audit'
  gem 'byebug'
  gem 'erb_lint'
  gem 'pry-byebug'
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'rubocop-rails'
  gem 'simplecov'
  gem 'simplecov-lcov', require: false
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  gem 'listen'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'puma'
  gem 'web-console'
end

group :test do
  gem 'committee', '~> 4.4'
  gem 'fakeredis', '0.9.0'
  gem 'minitest', '5.14.4'
  gem 'rails-controller-testing'
  gem 'vcr', '~> 6.1.0'
  gem 'webmock', '~> 3.18.1'
end
