#!/bin/bash --login

if [ "$#" -eq 0 ];then
#    echo "Usage: update.sh <development | production>"
#    exit 0
    ENV="production"
else
    ENV=$1
fi

git pull origin master
bundle install --deployment
bundle exec rake db:migrate RAILS_ENV=$ENV
bundle exec rake assets:clean RAILS_ENV=$ENV
bundle exec rake assets:precompile RAILS_ENV=$ENV
bundle exec rake sunspot:solr:reindex RAILS_ENV=$ENV

