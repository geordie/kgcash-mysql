#!/bin/bash

set -e

rm -f tmp/pids/server.pid
export SECRET_KEY_BASE="$(bundle exec rake secret)"

# configure database
bundle exec rake db:create
bundle exec rake db:migrate

# run service
exec bundle exec rails s -p 8080 -b '0.0.0.0' -e production
