#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /code/tmp/pids/server.pid

bundle exec whenever > /code/tess.crontab
supercronic /code/tess.crontab &

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"