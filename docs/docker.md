# Docker

TeSS can be run using Docker for development and in production.

## Prerequisites

In order to run TeSS, you need to have the following prerequisites installed.

- Git
- Docker and Docker Compose

These prerequisites a re out of scope for this document but you can find more information about them at the following links:

- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/)

## Quick Setup (Docker, development)

This guide is designed to get you up and running with as few commands as possible.

### Clone the repository and change directory

    git clone https://github.com/ElixirTeSS/TeSS.git && cd TeSS

### Create .env file

Although this file will work out of the box, it is recommended that you update it with your own values (especially the password!).

    cp env.sample .env

### Compose Up

    docker-compose up -d

### Setup the database (migrations + seed data + create admin user)

    docker-compose run app bundle exec rake db:setup

### _Optional_: pgAdmin Setup

If you want to use pgAdmin, you will need to add the database to your pgAdmin installation. You need to use the name of the database container along withe the DB_NAME, DB_USERNAME and DB_PASSWORD environment variables in your .env file.

### Access TeSS

TeSS is accessible at the following URL:

<http://localhost:3000>

## Testing

TODO

## Solr

To force Solr to reindex all documents, you can run the following command:

    docker-compose run app bundle exec rake sunspot:reindex

## Development Commands

Update the Gemfile.lock

    docker-compose run app bundle install

Update all Gems

    docker-compose run app bundle update --all

Update specific Gem

    docker-compose run app bundle update <gem>

Rebuild the tess-app image when composing up.

    docker-compose up -d --build

## Production

First setup your production configuration by creating and editing the `.env` file

    cp env.sample .env

*Important* make sure the various and credentials are changed! You can set some random values for these fields like so:

    sed s/SECRET_KEY_BASE=.*/SECRET_KEY_BASE=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32`/ -i .env
    sed s/DB_PASSWORD=.*/DB_PASSWORD=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`/ -i .env
    sed s/ADMIN_PASSWORD=.*/ADMIN_PASSWORD=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16`/ -i .env

Make sure to also set `HOSTNAME`, `CONTACT_EMAIL`, `ADMIN_EMAIL` and `ADMIN_USERNAME`.

The production deployment is configured in the `docker-compose-prod.yml` file.

    docker-compose -f docker-compose-prod.yml up -d

### Other production tasks

Run initial database setup

    docker-compose run app bundle exec rake db:setup

Run database migrations:

    docker-compose run app bundle exec rake db:migrate

Precompile the assets, necessary if any CSS/JS/images are changed after building the image:

    docker-compose run app bundle exec rake assets:clean && bundle exec rake assets:precompile

Reindex Solr

    docker-compose run app bundle exec rake sunspot:reindex