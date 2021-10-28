#!/bin/bash

ENV="production"

# stop services
sudo service nginx stop
sudo service unicorn_tess stop

# backup database
sudo sh ./scripts/pgsql_backup.sh postgres tess_$ENV ./shared/backups --exclude-schema=audit

# rebuild rails environment
git pull origin master
bundle config set --local deployment 'true'
bundle config set --local path 'vendor/bundle'
bundle install
bundle exec rake db:migrate RAILS_ENV="$ENV"
bundle exec rake assets:clean RAILS_ENV="$ENV"
bundle exec rake assets:precompile RAILS_ENV="$ENV"
bundle exec rake sunspot:solr:reindex RAILS_ENV="$ENV"

# run tests
bundle exec rake db:migrate RAILS_ENV=test
bundle exec rake db:setup RAILS_ENV=test
bundle exec rake db:test:prepare
bundle exec rails test

# restart sidekiq
sudo touch tmp/restart.txt
pkill -f sidekiq
bundle exec sidekiq -e "$ENV" &

# update scheduled tasks
whenever --update-crontab --set db_user="$PRODUCTION_DB_USER"

# restart logrotate
sudo service logrotate restart

# start services
sudo service unicorn_tess start
sudo service nginx start
#-- end of file --#
