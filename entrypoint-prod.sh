#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /code/tmp/pids/server.pid

#run migrations
bundle exec rake db:migrate

# precompile assets
bundle exec rake assets:clean
bundle exec rake assets:precompile

# reindex solr
bundle exec rake sunspot:solr:reindex

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"