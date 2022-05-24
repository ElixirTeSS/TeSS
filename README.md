# TeSS

**Training eSupport System** using Ruby on Rails.

TeSS is a Rails 5 application.

[![CircleCI](https://circleci.com/gh/nrmay/TeSS/tree/master.svg?style=svg)](https://circleci.com/gh/nrmay/TeSS/tree/master)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/fbe7186d5f2e43e890ec4f5c76445e33)](https://www.codacy.com/gh/nrmay/TeSS/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=nrmay/TeSS&amp;utm_campaign=Badge_Grade)
[![Codacy Badge](https://app.codacy.com/project/badge/Coverage/fbe7186d5f2e43e890ec4f5c76445e33)](https://www.codacy.com/gh/nrmay/TeSS/dashboard?utm_source=github.com&utm_medium=referral&utm_content=nrmay/TeSS&utm_campaign=Badge_Coverage)

## Versions
See the [Change Log](./CHANGE_LOG.md) for details of themes and issues associated with each version.

## Setup
Below is an example guide to help you set up TeSS in development mode. More comprehensive guides on installing
Ruby, Rails, RVM, bundler, postgres, etc. are available elsewhere.

## System Dependencies
TeSS requires the following system packages to be installed:

-   PostgresQL
-   ImageMagick
-   A Java runtime
-   A JavaScript runtime
-   Redis

To install these under an Ubuntu-like OS using apt:

    $ sudo apt update
    $ sudo apt install git postgresql postgresql-contrib libpq-dev imagemagick openjdk-8-jre nodejs redis-server
    $ sudo apt upgrade

For Mac OS X:

    $ brew install postgresql && brew install imagemagick && brew install nodejs

And install the JDK from Oracle or OpenJDK directly (It is needed for the SOLR search functionality)

### TeSS Code

Clone the source code via git:

    $ git clone https://github.com/nrmay/TeSS.git
    $ cd TeSS

### RVM, Ruby, Gems
#### RVM and Ruby

It is typically recommended to install Ruby with RVM. With RVM, you can specify the version of Ruby you want
installed, plus a whole lot more (e.g. gemsets). Full installation instructions for RVM are [available online](http://rvm.io/rvm/install/).

To install these under an Ubuntu-like OS using apt:

    $ sudo apt-add-repository ppa:rael-gc/rvm
    $ sudo apt update
    $ sudo apt install rvm
    $ sudo usermod -a -G rvm <user>    # e.g. replace <user> with ubuntu

Then re-login as *user* to enable rvm.

TeSS was developed using Ruby 2.4.5 and we recommend using version 2.4.5 or higher. To install TeSS' current version of ruby and create a gemset, you
can do something like the following:

    $ rvm install `cat .ruby-version`
    $ rvm use --create `cat .ruby-version`@`cat .ruby-gemset`

#### Bundler
Bundler provides a consistent environment for Ruby projects by tracking and installing the exact gems and versions that are needed for your Ruby application.

To install it, you can do:

    $ gem install bundler

Note that program 'gem' (a package management framework for Ruby called RubyGems) gets installed when you install RVM so you do not have to install it separately.

#### Gems

Once you have Ruby, RVM and bundler installed, from the root folder of the app do:

    $ bundle install

This will install Rails, as well as any other gem that the TeSS app needs as specified in Gemfile (located in the root folder of the TeSS app).

### PostgreSQL

Install postgres and add a postgres user called 'tess_user' for the use by the TeSS app (you can name the user any way you like).
Make sure tess_user is either the owner of the TeSS database (to be created in the next step), or is a superuser.
Otherwise, you may run into some issues when running and managing the TeSS app.

If postres is not already running, you can start postgres with something like (passing the path to your database with -D):

    $ pg_ctl -D ~/Postgresql/data/ start

From command prompt, create *tess_user* and set its password:

    $ sudo -i -u postgres
    $ createuser -Prlds tess_user
    $ exit

> Handy Postgres/Rails tutorials:
>
> https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04
>
> http://robertbeene.com/rails-4-2-and-postgresql-9-4/

### Solr

TeSS uses Apache Solr to power its search and filtering system.

To start solr, run:

    $ bundle exec rake sunspot:solr:start

You can replace *start* with *stop* or *restart* to stop or restart solr. You can use *reindex* to reindex all records.

    $ bundle exec rake sunspot:solr:reindex

### Redis/Sidekiq

On macOS these can be installed and run as follows:

    $ brew install redis
    $ redis-server /usr/local/etc/redis.conf
    $ bundle exec sidekiq

For a Redis install on a Linux system there should presumably be an equivalent package.

### The TeSS application

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

#### Setup Administrators

Once you have a local TeSS succesfully running, you may want to setup administrative users. To do this register a new account in TeSS through the registration page. Then go to the applications Rails console:

    $ bundle exec rails c

Find the user and assign them the administrative role. This can be completed by running this (where myemail@domain.co is the email address you used to register with):

    2.2.6 :001 > User.find_by_email('myemail@domain.co').update_attributes(role: Role.find_by_name('admin'))

#### Live deployment

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

### Basic API

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
            "description": "This API is fun and easy",
            "doi": "Put some stuff in here",
            "contact": "details of person or organisation",
            "keywords": ["key", "words"],
            "licence": "a valid licence"
        }
    }

A bundle install and rake db:migrate, followed by saving the user as mentioned above, should be enough to get this
working.

#### Rake tasks

To find suggestions of EDAM topics for materials, you can run this rake task. This requires redis and sidekiq to be running as it will add jobs to a queue. It uses BioPortal Annotator web service against the materials description to create suggestions

    bundle exec rake tess:add_topic_suggestions

#### Database Backup and Restore

The following scripts can be used to backup and restore the database:

     $ sh scripts/pgsql_backup.sh

     $ sh scripts/pgsql_restore.sh

Or, you can run the backup script as follows:

    $ sh scripts/pgsql_backup.sh tess_user tess_development ./shared/backups --exclude-schema=audit

The parameters are as follows:

1.  user: e.g. *tess_user*
2.  database: e.g. *tess_development*, *tess_production*
3.  backup folder: e.g. ./shared/backups
4.  addtional parameters: e.g. --excluded-schema=audit

Note: sql files are stored with timestamped names as follows:

-  folder/database.YYYYMMDD-HHMMSS.\[schema,data\].sql
-  eg. ~/TeSS/shared/backups/tess_development-20210524-085138.data.sql

And, you can run the restore script as follows:

    $ sh scripts/pgsql_restore.sh tess_user tess_production ./shared/backups/tess_production.20210524-085138.schema.sql ./shared/backups/tess_production.20210524-085138.data.sql

With the parameters:

1.  user: e.g. *tess_user*
2.  database: e.g. *tess_development*, *tess_production*
3.  schema file: e.g. ./shared/backups/tess_development.20210524-085138.schema.sql
4.  data file: e.g. ./shared/backups/tess_development.20210524-085138.data.sql


Note: these scripts have been adapted from the repository:
[fabioboris/postgresql-backup-restore-scripts](https://github.com/fabioboris/postgresql-backup-restore-scripts)
-  made available under the MIT License (MIT)
-  Copyright (c) 2013 Fabio Agostinho Boris &lt;fabioboris@gmail.com&gt;
