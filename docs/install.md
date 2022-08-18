# Install

The following guide is for installing TeSS natively (without Docker) on an Ubuntu-like OS. 
Some notes on installing under Mac OSX are also provided.

## Setup

Below is an example guide to help you set up TeSS in development mode. More comprehensive guides on installing
Ruby, Rails, RVM, bundler, postgres, etc. are available elsewhere.

## System Dependencies

TeSS requires the following system packages to be installed:

- PostgresQL
- ImageMagick
- A Java runtime
- A JavaScript runtime
- Redis

To install these under an Ubuntu-like OS using apt:

    sudo apt-get install git postgresql libpq-dev imagemagick nodejs redis-server openjdk-11-jdk

For Mac OS X:

    brew install postgresql && brew install imagemagick && brew install nodejs

And install the Java 11 JDK from Oracle or OpenJDK directly (it is needed for the Solr search functionality).

## TeSS Code

Clone the TeSS source code via git:

    git clone https://github.com/ElixirTeSS/TeSS.git

    cd TeSS

## RVM, Ruby, Gems

### RVM and Ruby

It is typically recommended to install Ruby with RVM. With RVM, you can specify the version of Ruby you want
installed. Full installation instructions for RVM are [available online](http://rvm.io/rvm/install/).

To install TeSS' current version of ruby and create a gemset, you can do something like the following:

    rvm install `cat .ruby-version`

    rvm use --create `cat .ruby-version`@`cat .ruby-gemset`

### Bundler

Bundler provides a consistent environment for Ruby projects by tracking and installing the exact gems and versions that are needed for your Ruby application.

To install it, you can do:

    gem install bundler

Note that program 'gem' (a package management framework for Ruby called RubyGems) gets installed when you install RVM so you do not have to install it separately.

### Gems

Once you have Ruby, RVM and bundler installed, from the root folder of the app do:

    bundle install

This will install Rails, as well as any other gem that the TeSS app needs as specified in Gemfile (located in the root folder of the TeSS app).

## PostgreSQL

Install postgres and add a postgres user called 'tess_user' for the use by the TeSS app (you can name the user any way you like).
Make sure tess_user is either the owner of the TeSS database (to be created in the next step), or is a superuser.
Otherwise, you may run into some issues when running and managing the TeSS app.

On Mac OS X, normally you'd start postgres with something like (passing the path to your database with -D):

    pg_ctl -D ~/Postgresql/data/ start

### Create the database owner

From command prompt:

    createuser --superuser tess_user

_(Note: You may need to run the above, and following commands as the `postgres` user: `sudo su - postgres`)_

### Set the database owner's password and permissions

Connect to your postgres database console as database admin 'postgres' (modify to suit your postgres database installation):

    sudo -u postgres psql

Or from Mac OS X

    sudo psql postgres

From the postgres console, set password for user 'tess_user':

    postgres=# \password tess_user

_If your tess_user is not a superuser, make sure you grant it a privilege to create databases:_

    postgres=# ALTER USER tess_user CREATEDB;

Handy Postgres/Rails tutorials:

<https://www.digitalocean.com/community/tutorials/how-to-use-postgresql-with-your-ruby-on-rails-application-on-ubuntu-14-04>
<http://robertbeene.com/rails-4-2-and-postgresql-9-4/>

## Solr

TeSS uses Apache Solr to power its search and filtering system.

Double check you are using Java 11:

    java -version

If not, you can switch using the following command:
    
    sudo update-alternatives --config java

### Install

Run the following commands to download and install solr into /opt/, and have it run as a "service" that will start on boot.

    cd /opt
    sudo wget https://downloads.apache.org/lucene/solr/8.11.1/solr-8.11.1.tgz
    sudo tar xzf solr-8.11.1.tgz solr-8.11.1/bin/install_solr_service.sh --strip-components=2
    sudo bash ./install_solr_service.sh solr-8.11.1.tgz

### Starting/stopping solr

Make sure solr is started using:

    sudo service solr start
    
If you need to stop it for whatever reason, run:

    sudo service solr stop

By default, solr should be running at localhost:8983

### Create a "collection"

Next, create a collection for TeSS to use (assuming TeSS is checked out at `/home/tess/TeSS`):

    sudo su - solr -c "/opt/solr/bin/solr create -c tess -d /home/tess/TeSS/solr/conf"

`tess` here is the collection name, which should match what is configured in your `config/sunspot.yml`.

### Re-indexing

If you ever need to re-index your TeSS data, for example if you have existing data in your TeSS database and are using 
a new collection, you can run the following command:

    bundle exec rake seek:reindex_all

## Redis/Sidekiq

TeSS uses Redis to handle caching of various things (geocoding results etc.) as well as sidekiq jobs (asynchronous tasks).

To install run:

    sudo apt-get install redis

On macOS these can be installed and run as follows:

    brew install redis
    redis-server /usr/local/etc/redis.conf

And to run sidekiq to process async jobs:

    bundle exec sidekiq

## The TeSS Application

From the app's root directory, create several config files by copying the example files.

    cp config/tess.example.yml config/tess.yml

    cp config/sunspot.example.yml config/sunspot.yml

    cp config/secrets.example.yml config/secrets.yml

    cp config/ingestion.example.yml config/ingestion.yml

Edit config/secrets.yml to configure the database name, user and password defined above.

Edit config/secrets.yml to configure the app's secret_key_base which you can generate with:

    bundle exec rake secret

Create the databases:

    bundle exec rake db:create:all

Create the database structure and load in seed data:

_Note: Ensure you have started Solr before running this command!_

    bundle exec rake db:setup

Start the application:

    bundle exec rails server

Access TeSS at:

<http://localhost:3000>

_(Optional) Run the test suite:_

    bundle exec rake db:test:prepare

    bundle exec rake test

### Setup Administrators

Once you have a local TeSS successfully running, you may want to setup administrative users. To do this register a new account in TeSS through the registration page.

Then go to the applications Rails console:

    bundle exec rails c

Find the user and assign them the administrative role. This can be completed by running this (where myemail@domain.co is the email address you used to register with):

    2.2.6 :001 > User.find_by_email('myemail@domain.co').update(role: Role.find_by_name('admin'))

## Production

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

****