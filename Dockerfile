FROM ruby:2.3.3
RUN apt-get update -qq && apt-get install -y build-essential mysql-client libpq-dev nodejs
RUN mkdir /kgcash
WORKDIR /kgcash
ADD Gemfile /kgcash/Gemfile
ADD Gemfile.lock /kgcash/Gemfile.lock
RUN bundle install
ADD . /kgcash
# Reset entrypoint to override base image.
ENTRYPOINT []

# Use foreman to start processes. $FORMATION will be set in the pod
# manifest. Formations are defined in Procfile.
CMD bundle exec foreman start --formation "$FORMATION"
