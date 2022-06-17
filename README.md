# TeSS

[ELIXIR's](https://www.elixir-europe.org/) Training e-Support Service using Ruby on Rails.

[![Actions Status](https://github.com/ElixirTeSS/TeSS/workflows/Test/badge.svg)](https://github.com/ElixirTeSS/TeSS/actions)

## Installation

Using docker: see [here](docs/docker.md)

Native: see [here](docs/install.md)

## Basic API

A record can be viewed as json by appending .json, for example:

    http://localhost:3000/materials.json
    http://localhost:3000/materials/1.json

The materials controller has been made token authenticable, so it is possible for a user with an auth token to post
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
            "short_description": "This API is fun and easy",
            "doi": "Put some stuff in here"
        }
    }

A bundle install and rake db:migrate, followed by saving the user as mentioned above, should be enough to get this
working.

## Rake tasks

To find suggestions of EDAM topics for materials, you can run this rake task. This requires redis and sidekiq to be running as it will add jobs to a queue. It uses BioPortal Annotator web service against the materials description to create suggestions

    bundle exec rake tess:add_topic_suggestions

## Live deployment

Although designed for CentOS, this document can be followed quite closely to set up a Rails app to work with Apache and Passenger:

    https://www.digitalocean.com/community/tutorials/how-to-setup-a-rails-4-app-with-apache-and-passenger-on-centos-6

To set up TeSS in production, do:

    bundle exec rake db:setup RAILS_ENV=production

which will do db:create, db:schema:load, db:seed. If you want the DB dropped as well:

    bundle exec rake db:reset RAILS_ENV=production

...which will do db:drop, db:setup

    unset XDG_RUNTIME_DIR

(may need setting in ~/.profile or similar if rails console moans about permissions.)

Delete all from Solr if need be and reindex it:

    curl http://localhost:8983/solr/update?commit=true -d  '<delete><query>*:*</query></delete>'

    bundle exec rake sunspot:solr:reindex RAILS_ENV=production

Create an admin user and assign it appropriate 'admin' role bu looking up that role in console in model Role (default roles should be created automatically).

The first time and each time a css or js file is updated:

    bundle exec rake assets:clean RAILS_ENV=production

    bundle exec rake assets:precompile RAILS_ENV=production

Restart your Web server.

---

### Scraper documentation

When running the scrapers a file ingestion.yml needs to exist with the structure as seen in ingestion.example.yml. A ContentProvider class object needs to exist in the db with the same name as the provider given in the sources list.  
For manually running the scraper:
    rake tess:automated_ingestion
