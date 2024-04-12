docker-compose up -d --build
# docker-compose up -d
docker-compose run app bundle install
docker-compose run app bundle exec rake db:setup
docker-compose run app bundle exec rake sunspot:reindex
