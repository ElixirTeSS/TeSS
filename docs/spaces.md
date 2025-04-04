# Multi-space TeSS

A multi-space enabled TeSS will set the current space based on the Host header of the incoming request 
(if there is a Space defined with that host, otherwise it will fallback to the default space).

# Development

To allow your local development server to respond to requests to these hosts, 
edit your hosts file (`/etc/hosts` on Linux) to include something like the following, e.g.:

```
127.0.0.1	plants.mytess.training
127.0.0.1	astro.mytess.training
127.0.0.1	whatever.mytess.training
```

This will ensure that if you visit e.g. plants.mytess.training, your browser will route it to your local development server
(you may need to restart your browser after changing the hosts file).

To ensure your Rails application accepts requests to the hosts provided above, you will also need to create a 
file `config/initializers/hosts.rb` and add the necessary hosts to Rails' config:

```ruby
Rails.application.config.hosts << '.mytess.training' if Rails.env.development?
```

# Production

To run a multi-space TeSS instance in production you will need to:

* Add a DNS record with a wildcard (e.g. *.mytess.training) to point your server
* Configure your web server (e.g. Apache) to respond to requests to these wildcard domains (e.g. `ServerAlias *.mytess.training`)
* Acquire a wildcard SSL certificate (e.g. via Let's Encrypt/Certbot: <https://certbot.eff.org/instructions?ws=apache&os=snap&tab=wildcard>)
