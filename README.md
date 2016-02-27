# TeSS

[ELIXIR's](https://www.elixir-europe.org/) Training e-Support Service using Ruby on Rails.

TeSS is a Rails 4 application.

[![Build Status](https://travis-ci.org/ElixirUK/TeSS.svg?branch=master)](https://travis-ci.org/ElixirUK/TeSS)

# Setup
Below is an example guide to help you set up TeSS in development mode. More comprehensive guides on installing
Ruby, Rails, RVM, bundler, postgres, etc. are available elsewhere.

## RVM, Ruby, Bundler, Rails
### RVM and Ruby

It is typically recommended to install Ruby with RVM. With RVM, you can specify the version of Ruby you want
installed, plus a whole lot more (e.g. gemsets). Full installation instructions for RVM are [available online](http://rvm.io/rvm/install/).

TeSS was developed using Ruby 2.2 and we recommend using version 2.2 or higher. To install it (after you installed RVM) and set up a gemset 'tess', you
can do something like the following:

 * `rvm install ruby-2.2-head`
 * `rvm use --create ruby-2.2-head@tess`

### Bundler
 Bundler provides a consistent environment for Ruby projects by tracking and installing the exact gems and versions that are needed for your Ruby application.

 To install it, you can do:

`$ gem install bundler`

Note that program 'gem' (a package management framework for Ruby called RubyGems) gets installed when you install RVM so you do not have to install it separately.

### Rails

Once you have Ruby, RVM and bundler installed, from the root folder of the app do:

`$ bundle install`

This will install Rails, as well as any other gem that the TeSS app needs as specified in Gemfile (located in the root folder of the TeSS app).

To just install Rails 4, you can do (at the time of this writing we worked with Rails 4.2):

`$ gem install rails -v 4.2`

## PostgreSQL

1. Install postgres and add a postgres user called 'tess_user' for the use by the TeSS app (you can name the user any way you like).
Make sure tess_user is either the owner of the TeSS database (to be created in the next step), or is a superuser.
Otherwise, you may run into some issues when running and managing the TeSS app.

 From command prompt:
 * `$ createuser --superuser tess_user`

 Connect to your postgres database console as database admin 'postgres' (modify to suit your postgres database installation):
 * `$ psql -U postgres`

 From the postgres console, set password for user 'tess_user':
 * `postgres=# \password tess_user`

 If your tess_user it not a superuser, make sure you grant it a privilege to create databases:
 * `ALTER USER tess_user CREATEDB;`

2. Connect to postgres console as tess_user and create database 'tess_development' (or use any other name you want).

 To connect to postgres console do (modify to suit your postgres database installation):
 * `$ psql -U tess_user`

 From postgres console, as user tess_user, do:
 * `postgres=# create database tess_development;`

3. If your tess_user it not superuser, perform various GRANT commands (make sure you connect as database superuser/admin to your postgres console):
 * `postgres=# GRANT ALL ON tess_development TO tess_user;`
 * `postgres=# \connect tess_development;`
 * `tess_development=# GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO tess_user;`

4. Test that you can now connect to the database from command prompt with:
 * `$ psql -U tess_user -W -d tess_development`

> Handy Postgres/Rails tutorials:
>
> https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04
>
> http://robertbeene.com/rails-4-2-and-postgresql-9-4/

## SOLR

To start solr, in your commandline run:

`$ rake sunspot:solr:start`

You can replace *start* with *stop* or *restart* to stop or restart solr. You can use *reindex* to reindex all records. 

`$ rake sunspot:solr:reindex`


## The TeSS App

1. From the app's root directory, copy config/example_secrets.yml to config/secrets.yml.

 `$ cp config/example_secrets.yml config/secrets.yml`

2. Edit config/secrets.yml (or config/database.yml - depending on your preference) to configure the database name, user and password defined above.

3. Edit config/secrets.yml to configure the app's secret_key_base which you can generate with:

 `$ rake secret`

4. Run:
 * `$ bundle install` (if you have not already)
 * `$ rake db:setup`
 * `$ rake db:migrate`

5. You should be ready to fire up TeSS in development mode:
 * `$ rails server`

6. Access TeSS at:
 * [http://localhost:3000](http://localhost:3000)

### Live deployment

Although designed for CentOS, this document can be followed quite closely to set up TeSS to work with Apache and Passenger:

    https://www.digitalocean.com/community/tutorials/how-to-setup-a-rails-4-app-with-apache-and-passenger-on-centos-6

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
