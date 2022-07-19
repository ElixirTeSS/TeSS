#!/bin/sh

#    echo "Usage: update.sh <development | production>"
#    exit 0
if [ -z $1 ]
then
  ENV=$1
else
  ENV="development"
fi

export RAILS_ENV=$ENV

# rebuild rails environment
git pull
bundle install --deployment
bundle exec rake db:migrate
bundle exec rake sunspot:solr:reindex
bundle exec rake assets:cleans
bundle exec rake assets:precompile
bundle exec rake tmp:clear
# update scheduled tasks
whenever --update-crontab --set environment="$ENV"

# restart services
touch tmp/restart.txt
pkill -f sidekiq
bundle exec sidekiq -d -e "$ENV" -L /tmp/sidekiq.log

