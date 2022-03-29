# frozen_string_literal: true
#
source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.2.6.2'

gem "bootsnap", ">= 1.1.0", require: false # New Rails 5.2 default gem

# Use postgresql as the database for Active Record
gem 'pg'

# For installing PG on macs:
gem 'lunchy'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# See https://github.com/rails/execjs#readme for more supported runtimes
#gem 'therubyracer'#, platforms: :ruby

# CRUD of resources via a UI
gem 'rails_admin'
gem 'haml', '~> 5.0.4' # Rails admin needs this, but doesn't fix the version to one that works with Rails 5.2

# Authentication
gem 'devise'
gem 'omniauth_openid_connect'
gem 'devise_invitable', '~> 2.0.5'

# Activity logging
gem 'public_activity', '~> 1.6.4', git: 'https://github.com/chaps-io/public_activity', tag: 'v1.6.4'

gem 'simple_token_authentication', '~> 1.0'

gem 'bootstrap-sass', '>= 3.4.1'

gem 'font-awesome-sass', '~> 4.7.0'

gem 'friendly_id', '~> 5.2.4'

gem 'sunspot_rails', '~> 2.2.7'

gem 'sunspot_solr', '= 2.2.0'

gem 'progress_bar', '~> 1.1.0'

gem 'activerecord-session_store'

gem 'gravtastic', '~> 3.2.6'

gem 'dynamic_sitemaps', github: 'lassebunk/dynamic_sitemaps', branch: 'master'

gem 'whenever', '~> 1.0.0'

# These are required for Sidekiq, to look up scientific topics
gem 'httparty'
gem 'sidekiq', '~> 6.4.0'
gem 'slim'

# Use jquery as the JavaScript library
gem 'jquery-rails'
gem 'jquery-qtip2-wrapper-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
gem 'jquery-turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder'
# bundle exec rake doc:rails generates the API under doc/api.

group :doc do
  gem 'sdoc', '>= 0.4.0'
  gem 'json', '>= 2.3.0'
  gem 'rdoc', '>= 6.3.1'
end

# Gem for creating before_validation callbacks for stripping whitespace
gem 'auto_strip_attributes', '~> 2.0'

# Gem for validating URLs
gem 'validate_url', '~> 1.0.2'

# Gem for simple form: https://github.com/heartcombo/simple_form
gem 'simple_form'
gem 'country_select', '<= 4.0.0'

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
gem 'by_star', '~> 2.2.1' #, git: 'git://github.com/radar/by_star.git', tag: 'v2.2.1'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
#gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

gem 'handlebars_assets'

gem 'paperclip', '~> 5.2.1'

gem 'icalendar', '~> 2.4.1'

gem 'bootstrap-datepicker-rails', '~> 1.6.4.1'

gem 'rack-cors', require: 'rack/cors'

gem 'recaptcha', require: 'recaptcha/rails'

gem 'linkeddata'

# Used for lat/lon rake task
gem 'geocoder'
gem 'redis', '< 5.0.0'

# set serializers version
gem 'active_model_serializers', '<= 0.10.7'

gem 'private_address_check'

# For the link monitor rake taks
gem 'time_diff'

# For internationalisation (i18n)
gem 'rails-i18n'
gem 'i18n_data'

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
  gem 'rails-assets-devbridge-autocomplete', '~> 1.2.26'
  gem 'rails-assets-eonasdan-bootstrap-datetimepicker', '~> 4.17.42'
  gem 'rails-assets-markdown-it', '~> 7.0.1'
  gem 'rails-assets-moment', '~> 2.15.0'
end

group :test do
  gem 'fakeredis'
  gem 'minitest', '5.10.3'
  gem 'rails-controller-testing'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'rubocop'
  gem 'simplecov'
  gem 'simplecov-lcov', require: false
  gem 'webmock', '~> 3.4.2'
end

group :development do
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring'
  gem 'listen'
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console'
end

group :production do
  gem 'therubyracer'
  gem 'unicorn'
  #gem 'passenger', '~> 5.1.11'
end
