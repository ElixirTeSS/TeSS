#!/bin/sh
set -u

# These paths are shared with Nginx through the Compose mounts.
certificate="/etc/letsencrypt/live/${TESS_BASE_HOST}/fullchain.pem"
renewal_config="/etc/letsencrypt/renewal/${TESS_BASE_HOST}.conf"

# Keep running so first issuance can retry and existing certificates renew regularly.
while :; do
  if [ -s "$certificate" ]; then
    # Migrate older certificates away from the nginx plugin to the shared webroot.
    if ! grep -q '^authenticator = webroot$' "$renewal_config" || \
      grep -q '^installer = ' "$renewal_config"; then
      # Remove the unavailable installer before Certbot validates the new settings.
      if ! python -c 'import sys; from configobj import ConfigObj; path = sys.argv[1]; config = ConfigObj(path); config["renewalparams"].pop("installer", None); config.write()' \
        "$renewal_config" || ! certbot reconfigure --cert-name "$TESS_BASE_HOST" \
        --webroot --webroot-path /var/www/certbot --non-interactive; then
        # Retry migration soon; do not renew with stale plugin settings.
        retry_after=5m
        sleep "$retry_after" &
        wait "$!"
        continue
      fi
    fi
    # Certbot renew only obtains a replacement when expiry is near.
    certbot renew --non-interactive || true
    retry_after=12h
  else
    # Use HTTP-01 through Nginx's /var/www/certbot webroot for first issuance.
    certbot certonly --webroot --webroot-path /var/www/certbot \
      --domain "$TESS_BASE_HOST" --email "$CERTBOT_EMAIL" \
      --agree-tos --no-eff-email --non-interactive || true
    retry_after=5m
  fi

  sleep "$retry_after" &
  wait "$!"
done