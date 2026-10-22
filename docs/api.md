# API

TeSS has 2 JSON APIs, a newer [JSON-API](https://jsonapi.org/) conformant API that is currently read-only,
and a legacy API that supports both read and write, but only for Events and Materials.

## Authentication

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

## JSON-API

A read-only API conforming to the [JSON-API](https://jsonapi.org/) specification.
Currently supports viewing, browsing, searching and filtering across Events, Materials, Workflows, Providers and Users.

[Click here to view documentation](https://tess.elixir-europe.org/api/json_api)

A record can be viewed through this API by appending `.json_api` to the URL, for example:

    http://localhost:3000/materials.json_api
    http://localhost:3000/materials/1.json_api

## Bioschemas, RO-Crate and FAIR Signposting

The pages of Materials and Events embed [Bioschemas](https://bioschemas.org/) JSON-LD, which can also be retrieved by
appending `.jsonld` to the URL:

    http://localhost:3000/materials/1.jsonld

Each Material and Event is also available as a [Detached RO-Crate](https://w3id.org/ro/crate/1.3), with the record's
URL as the Root Data Entity:

    http://localhost:3000/materials/1/ro-crate-metadata.json
    curl -H 'Accept: application/ld+json; profile="https://w3id.org/ro/crate"' http://localhost:3000/materials/1

These representations are advertised by [FAIR Signposting](https://signposting.org/FAIR/) links, in the HTTP `Link`
header and as `<link>` elements in the HTML head of the page: `describedby` for the Bioschemas JSON-LD, RO-Crate and
JSON-API, `cite-as` for the DOI (as an `https://doi.org/` URL), `author` for authors' ORCIDs, `license` and `type`.

    curl -I http://localhost:3000/materials/1

Integration tests that check these with the [signposting](https://pypi.org/project/signposting/) library against a
running TeSS are in [test/signposting](../test/signposting/test_signposting.py).

## Legacy API

A simple read/write API supporting Events and Materials.

[Click here to view documentation](https://tess.elixir-europe.org/api/legacy)

A record can be viewed as json by appending `.json` to the URL, for example:

    http://localhost:3000/materials.json
    http://localhost:3000/materials/1.json

### Example

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
