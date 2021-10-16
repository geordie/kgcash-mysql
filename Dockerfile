FROM ruby:2.5.9
RUN apt-get update -qq && \
  apt-get install -y build-essential mariadb-client default-libmysqlclient-dev nodejs cron && \
  apt-get clean autoclean && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt /var/lib/dpkg /var/lib/cache /var/lib/log && \
  mkdir /kgcash
WORKDIR /kgcash
ADD Gemfile /kgcash/Gemfile
ADD Gemfile.lock /kgcash/Gemfile.lock
RUN bundle config git.allow_insecure true & bundle install
ADD . /kgcash
# Reset entrypoint to override base image.
ENTRYPOINT []

# Use foreman to start processes. $FORMATION will be set in the pod
# manifest. Formations are defined in Procfile.
CMD bundle exec foreman start --formation "$FORMATION"
