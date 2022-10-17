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

### Development
TeSS can either be installed using [Docker](docs/docker.md#Development), or [natively](docs/install.md) on an Ubuntu-like OS 
(some Mac OSX guidance also provided).

### Production

To run TeSS in production, see either the [Docker guide](docs/docker.md#Production), 
or the [Ubuntu-like OS guide](docs/production.md).

## Customization

See [here](docs/customization.md) for an overview of how you can customize your TeSS deployment.

## API

TeSS has 2 JSON APIs, a newer [JSON-API](https://jsonapi.org/) conformant API that is currently read-only, 
and a legacy API that supports both read and write, but only for Events and Materials.

### Authentication

Both APIs use token authentication. You can see/change your API token from your TeSS profile page.

You can pass your credentials either using HTTP headers:
```
X-User-Email lisa@example.com
X-User-Token 65gONMyVZXXkgnksghzB  
```

or in your request:

```json
{
  "user_email" : "lisa@example.com",
  "user_token" : "65gONMyVZXXkgnksghzB",  
  "material": {
    "title": "API example",
    ...
  }
}
```

### JSON-API

A read-only API conforming to the [JSON-API](https://jsonapi.org/) specification.
Currently supports viewing, browsing, searching and filtering across Events, Materials, Workflows, Providers and Users.

[Click here to view documentation](https://tess.elixir-europe.org/api/json_api) 

A record can be viewed through this API by appending `.json_api` to the URL, for example:

    http://localhost:3000/materials.json_api
    http://localhost:3000/materials/1.json_api

### Legacy API

A simple read/write API supporting Events and Materials.
  
[Click here to view documentation](https://tess.elixir-europe.org/api/legacy)

A record can be viewed as json by appending `.json` to the URL, for example:

    http://localhost:3000/materials.json
    http://localhost:3000/materials/1.json

#### Example

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
