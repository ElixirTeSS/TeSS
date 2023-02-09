#!/bin/sh

#    echo "Usage: update_tess.sh <development | production>"
#    exit 0
if [ -z $1 ]
then
  ENV="production"
else
  ENV=$1
fi

export RAILS_ENV=$ENV

# rebuild rails environment
git pull --rebase
bundle install --deployment
bundle exec rake db:migrate
bundle exec rake assets:clean
bundle exec rake assets:precompile
bundle exec rake tmp:clear
# update scheduled tasks
bundle exec whenever --update-crontab --set environment="$ENV"

# restart application
touch tmp/restart.txt

# restart sidekiq
systemctl --user restart sidekiq

