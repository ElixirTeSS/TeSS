[![Build Status](https://travis-ci.org/ElixirUK/TeSS.svg?branch=master)](https://travis-ci.org/ElixirUK/TeSS)

# TeSS

Work in progress to add basic models.


## Setup

Check the tessdbs repository for any necessary commands for Devise &c.

Also:

    rails g public_activity:migration
    rake db:migrate

public_activity Railscast: http://railscasts.com/episodes/406-public-activity?view=asciicast


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