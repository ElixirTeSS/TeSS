# Be sure to restart your server when you modify this file.

#Rails.application.config.session_store :cookie_store, key: '_tess_session'


# Trying a fix:
# https://stackoverflow.com/questions/16960041/devise-with-existing-database-401-unauthorized-using-valid-password
TeSS::Application.config.session_store :cookie_store, key: '_tess_session', domain: {
    production: 'tess.oerc.ox.ac.uk',
    development: 'localhost'
}.fetch(Rails.env.to_sym, :all)