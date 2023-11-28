# Training Hub
The [Scilifelab](https://www.scilifelab.se/) **T**raining **H**ub is dedicated to fostering a diverse and inclusive community of instructors and learners, where we can all gain new skills and benefit from the minds of many.

We are building a training portal from exisiting open source project [TeSS](https://github.com/ElixirTeSS/TeSS) where the life science community in Sweden can find opportunities to gain relevant skills, and experts can find support in creating training that captures their knowledge. 

## Getting Started
Training Hub can be installed using [Docker](docs/docker.md#Development). Just follow all the steps in the develop branch instead of master.

### Contributions to code
In order to contribute to code,
1. Start with develop branch, create your feature branch: name_feature. 
    E.g.,  I am working on creating search functionality so my branch name is harshita_searchfunc
    Once the project board is setup then we will even refine the naming convention of feature branches to specific issue title no.

2. Create a PR for your feature branches and add either Nina or Harshita in the reviewer.
After creating a PR, drop the message in the slack with PR url and notify the reviewer in the #trainghub-portal channel.

3. Branch linked to Elixir/TeSS is master. It is in read only mode and can only sync fork from its upstream repository. No developer should push code to master.

# TeSS

[![Actions Status](https://github.com/ElixirTeSS/TeSS/workflows/CI/badge.svg)](https://github.com/ElixirTeSS/TeSS/actions)

[ELIXIR's](https://www.elixir-europe.org/) **T**raining **e**-**S**upport **S**ervice - A Ruby on Rails application providing a portal for registering and discovering training events and materials.

The TeSS code is open source and available under a [BSD 3-Clause license](LICENSE). You are free to [use it outside of ELIXIR](docs/customization.md), with minimal restrictions on its use and distribution. If you do create your own version/fork of TeSS, we welcome and encourage [contributing](CONTRIBUTING.md) your changes back to the main TeSS codebase.

## Features

- Faceted browsing/filtering
- Full-text search
- Flexible user authentication
- Automated, periodic import (scraping) of resources
- Email subscriptions
- JSON API
- Embeddable [widgets](https://github.com/ElixirTeSS/TeSS_widgets)
- iCal export
- Semantic web-friendly - [Bioschemas](https://bioschemas.org/) and [EDAM Ontology](https://edamontology.org/) integration
- Administration and curation features for managing users and content
- Customization options

## Contributing

Interested in contributing to TeSS? Check out [our guide](CONTRIBUTING.md) on the different ways you can contribute.

## Architecture overview

TeSS makes use of the following services to function:
- PostgreSQL - Database
- Solr - Search
- Sidekiq - Asynchronous tasks
- Redis - Caching

and also integrates with several external services:
- [Nominatim](https://nominatim.org/) - Geocoding
- [Google Maps API](https://developers.google.com/maps) - Maps and address autocompletion
- [LS-Login](https://lifescience-ri.eu/ls-login/) - Authentication
- [bio.tools](https://bio.tools/) - Tool suggestions
- [FAIRsharing](https://fairsharing.org/) - Standard, policy and database suggestions

## Installation

### Development
TeSS can either be installed using [Docker](docs/docker.md#Development), or [natively](docs/install.md) on an Ubuntu-like OS 
(some Mac OSX guidance also provided).

### Production

To run TeSS in production, see either the [Docker guide](docs/docker.md#Production), 
or the [Ubuntu-like OS guide](docs/production.md).

## Customization

See [here](docs/customization.md) for an overview of how you can customize your TeSS deployment.

## API

See [here](docs/api.md) for details on programmatic access to TeSS via its API.
