# Docker

TeSS can be run using Docker for [development](#development) and in [production](#production).

## Prerequisites

In order to run TeSS, you need to have the following prerequisites installed.

- Git
- Docker and Docker Compose

These prerequisites are out of scope for this document but you can find more information about them at the following links:

- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)

## Development

This guide is designed to get you up and running with as few commands as possible.

### Clone the repository and change directory

    git clone https://github.com/ElixirTeSS/TeSS.git && cd TeSS

### Configuration

Create the `.env` file:

    cp env.sample .env

Although this file will work out of the box, it is recommended that you update it with your own values (especially the password!).

Create TeSS configuration files:

    cp config/tess.example.yml config/tess.yml
    cp config/secrets.example.yml config/secrets.yml

`tess.yml` is used to configure features and branding of your TeSS instance. `secrets.yml` is used to hold API keys etc.

*Note: If changes are made to these files the containers will need to be restarted.*

### Install gems and set up the database (migrations + seed data + create admin user)

    docker-compose run app bundle install
    docker-compose run app bundle exec rake db:setup

### Start services

    docker-compose up -d

### Access TeSS

TeSS is accessible at the following URL:

<http://localhost:3000>

### Testing

The full test suite can be run using the following command:

    docker-compose run test

To run a specific test, you can override the command being passed:

    docker-compose run test rails test test/models/event_test.rb

### Solr

To force Solr to reindex all documents, you can run the following command:

    docker-compose exec app bundle exec rake sunspot:reindex

### Additional development commands

Install gems

    docker-compose exec app bundle install

Update all Gems

    docker-compose exec app bundle update --all

Update specific Gem

    docker-compose exec app bundle update <gem>

Rebuild the tess-app image when composing up.

    docker-compose up -d --build

## Production

### Configuration

Create the `.env` file:

    cp env.sample .env

**Important** make sure the various credentials are changed! You can set some random values for these fields like so:

    sed s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`/ -i .env
    sed s/DB_PASSWORD=.*/DB_PASSWORD=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`/ -i .env
    sed s/ADMIN_PASSWORD=.*/ADMIN_PASSWORD=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`/ -i .env

Make sure to also set `ADMIN_EMAIL` and `ADMIN_USERNAME` (please note `admin` is not available as a username).

Setup the TeSS configuration files: 

    cp config/tess.example.yml config/tess.yml
    cp config/secrets.example.yml config/secrets.yml

`tess.yml` is used to configure features and branding of your TeSS instance. `secrets.yml` is used to hold API keys etc.

The production deployment is configured in the `docker-compose-prod.yml` file.

Start services:

    docker-compose -f docker-compose-prod.yml up -d

Run initial database setup:

    docker-compose -f docker-compose-prod.yml exec app bundle exec rake db:setup DISABLE_DATABASE_ENVIRONMENT_CHECK=1

### Other production tasks

Run database migrations:

    docker-compose -f docker-compose-prod.yml exec app bundle exec rake db:migrate

Precompile the assets, necessary if any CSS/JS/images are changed after building the image:

    docker-compose -f docker-compose-prod.yml exec app bundle exec rake assets:clean && bundle exec rake assets:precompile

Reindex Solr:

    docker-compose -f docker-compose-prod.yml exec app bundle exec rake sunspot:reindex
