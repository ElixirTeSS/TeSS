FROM ruby:3.0

WORKDIR /code

COPY Gemfile Gemfile.lock ./
RUN gem install ruby-debug-ide
RUN bundle update
RUN bundle install

COPY . .

CMD ["./bin/rails", "server"]