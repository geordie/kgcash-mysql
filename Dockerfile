FROM ruby:3.0.3-alpine

RUN apk update && apk upgrade && \
  apk add build-base mariadb-client mariadb-dev nodejs git bash tzdata && \
  rm -rf /var/cache/apk/* && \
  mkdir /kgcash
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
