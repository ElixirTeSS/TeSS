#use ruby base image
FROM ruby:3.0.4

# set work dir
WORKDIR /code

# install dependencies
RUN apt-get update && apt-get install libpq-dev imagemagick nodejs -y

# install supercronic - a cron alternative
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e

RUN curl -fsSLO "$SUPERCRONIC_URL" \
 && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
 && chmod +x "$SUPERCRONIC" \
 && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
 && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

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
