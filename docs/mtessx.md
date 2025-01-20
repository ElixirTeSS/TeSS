# Development

## Simulating subdomains

A multi-space enabled TeSS will set the current space based on the subdomain of the incoming request.

To allow your local development server to respond to requests with a subdomain, 
edit your hosts file (`/etc/hosts` on Linux) to include something like the following, e.g.:

```
127.0.0.1	plants.mytess.training
127.0.0.1	astro.mytess.training
127.0.0.1	whatever.mytess.training
```

This will ensure that if you visit e.g. plants.mytess.training, your browser will route it to your local development server
(you may need to restart your browser after changing the hosts file).

Edit `config/hosts.rb` to ensure your Rails application accepts requests to the hosts provided above.

## Configuring spaces

Edit `tess.yml` to define spaces, e.g.:

```
  spaces:
    plants:
      name: TeSS Plants Community
    astro:
      name: TeSS Space Community
    whatever:
      name: The Whatever Space
```

(Your server will need to be restarted after changing this file)
