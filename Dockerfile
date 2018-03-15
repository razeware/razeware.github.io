FROM ruby:2.5.0-alpine3.7

RUN apk --update add nodejs build-base ruby-dev tzdata git

RUN mkdir /app
WORKDIR /app

RUN gem install bundler

ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock

RUN bundle install

ADD . /app
