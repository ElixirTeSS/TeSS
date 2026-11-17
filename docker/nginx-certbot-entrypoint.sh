#!/bin/sh
set -eu

certificate="/etc/letsencrypt/live/${TESS_BASE_HOST}/fullchain.pem"
tls_template=/etc/nginx/tess-ssl.conf.template
tls_config=/etc/nginx/sites-enabled/tess-ssl

# Build the HTTPS server block for this deployment's hostname.
render_tls_config() {
  envsubst '${TESS_BASE_HOST}' < "$tls_template" > "$tls_config"
}

# Nginx cannot load TLS directives until Certbot has issued the certificate.
if [ -s "$certificate" ]; then
  render_tls_config
else
  rm -f "$tls_config"
fi

# Watch for first issuance and renewals; Nginx reads certificate files on reload.
(
  # Record the current version so startup does not trigger an unnecessary reload.
  last_modified=
  if [ -s "$certificate" ]; then
    last_modified=$(stat -L -c %Y "$certificate")
  fi

  while :; do
    sleep 10
    if [ -s "$certificate" ]; then
      current_modified=$(stat -L -c %Y "$certificate")
      if [ "$current_modified" != "$last_modified" ]; then
        # The first certificate appears after startup, so its TLS config is not present yet.
        if [ ! -s "$tls_config" ]; then
          render_tls_config
        fi
        if nginx -t && nginx -s reload; then
          # Keep the old value on failure so the next polling interval retries.
          last_modified=$current_modified
        fi
      fi
    fi
  done
) &

exec nginx -g 'daemon off;'