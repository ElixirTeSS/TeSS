# TeSS

[![Actions Status](https://github.com/ElixirTeSS/TeSS/workflows/Test/badge.svg)](https://github.com/ElixirTeSS/TeSS/actions)

[ELIXIR's](https://www.elixir-europe.org/) Training e-Support Service using Ruby on Rails.

TeSS makes use of the following services to function:
- PostgreSQL - Database
- Solr - Search
- Sidekiq - Asynchronous tasks
- Redis - Caching
- Nominatim - Geocoding
- Google Maps API - Maps and address autocompletion

## Installation

Docker: see [here](docs/docker.md)

Native: see [here](docs/install.md)

## Customization

See [here](docs/customization.md) for an overview of how you can customize your TeSS deployment.

## Basic API

A record can be viewed as json by appending .json, for example:

    http://localhost:3000/materials.json
    http://localhost:3000/materials/1.json

The materials controller has been made token authenticatable, so it is possible for a user with an auth token to post
to it. To generate the auth token the user model must first be saved.

To create a material by posting, post to this URL:

    http://localhost:3000/materials.json

Structure the JSON thus:

    {
        "user_email": "you@your.email.com",
        "user_token": "your_authentication_token",
        "material": {
            "title": "API example",
            "url": "http://example.com",
            "description": "This API is fun and easy",
            "doi": "Put some stuff in here"
        }
    }

A bundle install and rake db:migrate, followed by saving the user as mentioned above, should be enough to get this
working.

## Rake tasks

To find suggestions of EDAM topics for materials, you can run this rake task. This requires redis and sidekiq to be running as it will add jobs to a queue. It uses BioPortal Annotator web service against the materials description to create suggestions

    bundle exec rake tess:add_topic_suggestions
