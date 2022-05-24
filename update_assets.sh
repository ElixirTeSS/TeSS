#!/bin/sh
#    echo "Usage: update_assets.sh <development | production>"
#    exit 0
if [ -z $1 ]
then
  ENV=$1
else
  ENV="development"
fi

# stop services
sudo service nginx stop
sudo service unicorn_tess stop

# rebuild rails environment
bundle exec rake assets:clean RAILS_ENV="$ENV"
bundle exec rake assets:precompile RAILS_ENV="$ENV"
bundle exec rake sunspot:solr:reindex RAILS_ENV="$ENV"

# start services
sudo service unicorn_tess start
sudo service nginx start
#-- end of file --#

