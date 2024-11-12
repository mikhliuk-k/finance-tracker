FROM ruby:3.3.4-alpine

RUN apk update && apk add --no-cache build-base

WORKDIR /app/

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . ./

ENTRYPOINT ["ruby", "app.rb"]
