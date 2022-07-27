# Customization

TeSS can be customized and configured in a variety of ways to suit the needs of your deployment.

## General configuration

General TeSS settings are configured in `config/tess.yml`. Examples of settings include:
- `base_url` - The base URL that this TeSS instance is deployed at. Used to generate full URLs in emails etc.
- `contact_email` - The address to which support requests should be sent.
- `site` - Various options for customizing the name and logo of this TeSS instance.
- `feature` - Enable/disable types of resource (Event, Material etc.).
- `feature` > `disabled` - Hide various fields.

Secure settings such as database credentials, API keys, email settings etc. can be configured in `config/secrets.yml`.

## Styles

To customize the appearance of TeSS, go into the themes folder (`app/assets/stylesheets/themes`) and make a copy 
of the default theme file (`default.scss`). In your copy, you can tweak any of the existing variables, add overrides for
any bootstrap variables (reference: https://github.com/twbs/bootstrap-sass/blob/master/assets/stylesheets/bootstrap/_variables.scss)
and add new CSS/SASS styles.

To enable your theme, edit `app/assets/stylesheets/mixins/variables.scss` and change the line:
```scss
@import "../themes/default";
```
to point to your new theme file...
```scss
@import "../themes/new_theme";
```

Be sure to recompile assets (`bundle exec rake assets:recompile`), or rebuild your docker image, 
and restart the application to apply the new styles.

## Text changes

Much of the static text content of TeSS is sourced from YML files stored in `config/locales`, e.g. `en.yml`. 

If you wish to alter any of this text, instead of modifying the files directly, create a new YML file under 
`config/locales/overrides` with the same locale suffix (e.g. `config/locales/overrides/my_app.en.yml`).

In that file, you add any strings you want to override, for example:
```yml
  en:
    home:
      welcome: Welcome to my new training portal!
```

Files in the `overrides` directory will be automatically loaded, except when in the Rails `test` environment. 

Read more about Rails' internationalization here: https://guides.rubyonrails.org/i18n.html
