FROM ruby:2.3.3
RUN apt-get update -qq && apt-get install -y build-essential mysql-client nodejs
RUN mkdir /kgcash
WORKDIR /kgcash
ADD Gemfile /kgcash/Gemfile
ADD Gemfile.lock /kgcash/Gemfile.lock
RUN bundle install
ADD . /kgcash
