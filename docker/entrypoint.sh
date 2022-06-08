#!/bin/bash
set -e

# compile assets
if [ "$RAILS_ENV" == "production" ]
then
  echo "COMPILING ASSETS"
  # using --trace prevents giving the feeling things have frozen up during startup
  bundle exec rake assets:precompile --trace
  bundle exec rake assets:clean --trace
fi

# Remove a potentially pre-existing server.pid for Rails.
rm -f /code/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"