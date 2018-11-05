# TeSS

[ELIXIR's](https://www.elixir-europe.org/) Training e-Support Service using Ruby on Rails.

TeSS is a Rails 5 application.

[![Build Status](https://travis-ci.org/ElixirTeSS/TeSS.svg?branch=master)](https://travis-ci.org/ElixirTeSS/TeSS)
[![Codacy Badge](https://api.codacy.com/project/badge/Coverage/11f7d36a8848462f98fa308abbec0121)](https://www.codacy.com/app/fbacall/TeSS?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=ElixirTeSS/TeSS&amp;utm_campaign=Badge_Coverage)

# Setup
Below is an example guide to help you set up TeSS in development mode. More comprehensive guides on installing
Ruby, Rails, RVM, bundler, postgres, etc. are available elsewhere.

## System Dependencies
TeSS requires the following system packages to be installed:
* PostgresQL
* ImageMagick
* A Java runtime
* A JavaScript runtime
* Redis

To install these under an Ubuntu-like OS using apt:

    $ sudo apt-get install git postgresql libpq-dev imagemagick openjdk-8-jre nodejs redis-server

For Mac OS X:

    $ brew install postgresql && brew install imagemagick && brew install nodejs

And install the JDK from Oracle or OpenJDK directly (It is needed for the SOLR search functionality)

## TeSS Code

Clone the TeSS source code via git:

    $ git clone https://github.com/ElixirTeSS/TeSS.git
    
    $ cd TeSS

## RVM, Ruby, Gems
### RVM and Ruby

It is typically recommended to install Ruby with RVM. With RVM, you can specify the version of Ruby you want
installed, plus a whole lot more (e.g. gemsets). Full installation instructions for RVM are [available online](http://rvm.io/rvm/install/).

TeSS was developed using Ruby 2.4.5 and we recommend using version 2.4.5 or higher. To install TeSS' current version of ruby and create a gemset, you
can do something like the following:

    $ rvm install `cat .ruby-version`

    $ rvm use --create `cat .ruby-version`@`cat .ruby-gemset`

### Bundler
Bundler provides a consistent environment for Ruby projects by tracking and installing the exact gems and versions that are needed for your Ruby application.

To install it, you can do:

    $ gem install bundler

Note that program 'gem' (a package management framework for Ruby called RubyGems) gets installed when you install RVM so you do not have to install it separately.

### Gems

Once you have Ruby, RVM and bundler installed, from the root folder of the app do:

    $ bundle install

This will install Rails, as well as any other gem that the TeSS app needs as specified in Gemfile (located in the root folder of the TeSS app).

## PostgreSQL

Install postgres and add a postgres user called 'tess_user' for the use by the TeSS app (you can name the user any way you like).
Make sure tess_user is either the owner of the TeSS database (to be created in the next step), or is a superuser.
Otherwise, you may run into some issues when running and managing the TeSS app.

Normally you'd start postgres with something like (passing the path to your database with -D):

    $ pg_ctl -D ~/Postgresql/data/ start

From command prompt:
 
    $ createuser --superuser tess_user

Connect to your postgres database console as database admin 'postgres' (modify to suit your postgres database installation):
 
    $ sudo -u postgres psql

Or from Mac OS X

    $ sudo psql postgres

From the postgres console, set password for user 'tess_user':
 
    postgres=# \password tess_user

*If your tess_user is not a superuser, make sure you grant it a privilege to create databases:*
 
    postgres=# ALTER USER tess_user CREATEDB;

> Handy Postgres/Rails tutorials:
>
> https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04
>
> http://robertbeene.com/rails-4-2-and-postgresql-9-4/

## Solr

TeSS uses Apache Solr to power its search and filtering system. 

To start solr, run:

    $ bundle exec rake sunspot:solr:start

You can replace *start* with *stop* or *restart* to stop or restart solr. You can use *reindex* to reindex all records. 

    $ bundle exec rake sunspot:solr:reindex


## Redis/Sidekiq

On macOS these can be installed and run as follows:

    $ brew install redis
    $ redis-server /usr/local/etc/redis.conf
    $ bundle exec sidekiq
    
For a Redis install on a Linux system there should presumably be an equivalent package.


## The TeSS Application

From the app's root directory, create several config files by copying the example files.

    $ cp config/tess.example.yml config/tess.yml

    $ cp config/sunspot.example.yml config/sunspot.yml

    $ cp config/secrets.example.yml config/secrets.yml

Edit config/secrets.yml to configure the database name, user and password defined above.

Edit config/secrets.yml to configure the app's secret_key_base which you can generate with:

    $ bundle exec rake secret

Create the databases:

    $ bundle exec rake db:create:all

Create the database structure and load in seed data:

*Note: Ensure you have started Solr before running this command!*  

    $ bundle exec rake db:setup

Start the application:

    $ bundle exec rails server

Access TeSS at:

[http://localhost:3000](http://localhost:3000)

*(Optional) Run the test suite:*

    $ bundle exec rake db:test:prepare

    $ bundle exec rake test

### Setup Administrators

Once you have a local TeSS succesfully running, you may want to setup administrative users. To do this register a new account in TeSS through the registration page. Then go to the applications Rails console: 

    $ bundle exec rails c

Find the user and assign them the administrative role. This can be completed by running this (where myemail@domain.co is the email address you used to register with):

    2.2.6 :001 > User.find_by_email('myemail@domain.co').update_attributes(role: Role.find_by_name('admin'))

### Live deployment

Although designed for CentOS, this document can be followed quite closely to set up a Rails app to work with Apache and Passenger:

    https://www.digitalocean.com/community/tutorials/how-to-setup-a-rails-4-app-with-apache-and-passenger-on-centos-6

To set up TeSS in production, do:

    $ bundle exec rake db:setup RAILS_ENV=production

which will do db:create, db:schema:load, db:seed. If you want the DB dropped as well:

    $ bundle exec rake db:reset RAILS_ENV=production

...which will do db:drop, db:setup

    $ unset XDG_RUNTIME_DIR 
    
(may need setting in ~/.profile or similar if rails console moans about permissions.)

Delete all from Solr if need be and reindex it:

    $ curl http://localhost:8983/solr/update?commit=true -d  '<delete><query>*:*</query></delete>'

    $ bundle exec rake sunspot:solr:reindex RAILS_ENV=production

Create an admin user and assign it appropriate 'admin' role bu looking up that role in console in model Role (default roles should be created automatically).

The first time and each time a css or js file is updated:

    $ bundle exec rake assets:clean RAILS_ENV=production

    $ bundle exec rake assets:precompile RAILS_ENV=production

Restart your Web server.

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


### Rake tasks

To find suggestions of EDAM topics for materials, you can run this rake task. This requires redis and sidekiq to be running as it will add jobs to a queue. It uses BioPortal Annotator web service against the materials description to create suggestions

    bundle exec rake tess:add_topic_suggestions
