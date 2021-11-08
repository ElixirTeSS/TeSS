#use ruby base image
FROM ruby:3

# set work dir
WORKDIR /code

# install dependencies
RUN apt update && apt install libpq-dev imagemagick nodejs -y

# copy gemfile
COPY Gemfile .

# install gems
RUN bundle install

# add degug gem
RUN gem install ruby-debug-ide

# copy main app (don't copy lock file - .dockerignore)
COPY . .

# expose port
EXPOSE 3000

# run rails server, need bind
CMD bundle exec rails server -b 0.0.0.0