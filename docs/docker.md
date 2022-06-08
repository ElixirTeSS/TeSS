# Docker

TeSS can be run using Docker for development and in production.

## Prerequisites

In order to run TeSS, you need to have the following prerequisites installed.

- Git
- Docker and Docker Compose

These prerequisites a re out of scope for this document but you can find more information about them at the following links:

- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/)

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

### Start services

    docker-compose up -d

### Setup the database (migrations + seed data + create admin user)

    docker-compose exec app bundle exec rake db:setup

### Access TeSS

TeSS is accessible at the following URL:

<http://localhost:3000>

### Testing

TODO

### Solr

To force Solr to reindex all documents, you can run the following command:

    docker-compose exec app bundle exec rake sunspot:reindex

### Additional development commands

Update the Gemfile.lock

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

*Important* make sure the various credentials are changed! You can set some random values for these fields like so:

    sed s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`/ -i .env
    sed s/DB_PASSWORD=.*/DB_PASSWORD=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`/ -i .env
    sed s/ADMIN_PASSWORD=.*/ADMIN_PASSWORD=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`/ -i .env

Make sure to also set `HOSTNAME`, `CONTACT_EMAIL`, `ADMIN_EMAIL` and `ADMIN_USERNAME`.

Setup the TeSS configuration files: 

    cp config/tess.example.yml config/tess.yml
    cp config/secrets.example.yml config/secrets.yml

`tess.yml` is used to configure features and branding of your TeSS instance. `secrets.yml` is used to hold API keys etc.

The production deployment is configured in the `docker-compose-prod.yml` file.

    docker-compose -f docker-compose-prod.yml up -d

### Other production tasks

Run initial database setup:

    docker-compose exec app bundle exec rake db:setup

Run database migrations:

    docker-compose exec app bundle exec rake db:migrate

Precompile the assets, necessary if any CSS/JS/images are changed after building the image:

    docker-compose exec app bundle exec rake assets:clean && bundle exec rake assets:precompile

Reindex Solr:

    docker-compose exec app bundle exec rake sunspot:reindex