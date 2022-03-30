#use ruby base image
FROM ruby:3.0.1

#set rails env
ENV RAILS_ENV=development

# set work dir
WORKDIR /code

# install dependencies
RUN apt update && apt install libpq-dev imagemagick nodejs -y

# copy gemfile
COPY Gemfile Gemfile.lock ./

# install gems
RUN bundle install

# add degug gem
RUN gem install ruby-debug-ide

# Clean up server.pid
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# expose port
EXPOSE 3000

# run rails server, need bind for docker
CMD bundle exec rails server -b 0.0.0.0