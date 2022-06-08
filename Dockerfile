#use ruby base image
FROM ruby:3.0.1

# set work dir
WORKDIR /code

# install dependencies
RUN apt-get update && apt-get install libpq-dev imagemagick nodejs -y

# copy gemfile
COPY Gemfile Gemfile.lock ./

# install gems
RUN bundle check || bundle install

# copy code
COPY . .

# precompile assets
RUN bundle exec rake assets:precompile

ENTRYPOINT ["docker/entrypoint.sh"]

# expose port
EXPOSE 3000

# run rails server, need bind for docker
CMD bundle exec rails server -b 0.0.0.0