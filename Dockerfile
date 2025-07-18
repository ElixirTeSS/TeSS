ARG RUBY_VERSION=3.3.8

#use ruby base image
FROM ruby:$RUBY_VERSION-slim AS base

# set work dir
WORKDIR /code

# install dependencies
RUN apt-get update \
    && apt-get install build-essential curl file git gnupg2 imagemagick libpq-dev libyaml-dev nodejs -y \
    && apt-get clean


# install supercronic - a cron alternative
ENV SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.1.12/supercronic-linux-amd64 \
    SUPERCRONIC=supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=048b95b48b708983effb2e5c935a1ef8483d9e3e

RUN curl -fsSLO "$SUPERCRONIC_URL" \
    && echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c - \
    && chmod +x "$SUPERCRONIC" \
    && mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}" \
    && ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic

ENTRYPOINT ["docker/entrypoint.sh"]

EXPOSE 3000


FROM base AS development

CMD bundle exec rails server -b 0.0.0.0


FROM base AS production

# copy gemfile
COPY Gemfile Gemfile.lock ./

# install gems
RUN bundle check || bundle install

# copy code
COPY . .

# precompile assets
RUN bundle exec rake assets:precompile


ARG CR

# chown to root group to allow rwx when pulling from container registry
# and do not bake secrets
RUN if [ "$CR" = "True" ]; then \
        mkdir -p /code && chown -R 0:0 /code \
        && chmod -R g+rwX /code \
        && rm -rf /code/config/tess.yml \
            /code/config/secrets.yml \
            .env; \
    fi


# run rails server, need bind for docker
CMD bundle exec whenever > /code/tess.crontab \
    && (supercronic /code/tess.crontab &) \
    && bundle exec rails server -b 0.0.0.0
