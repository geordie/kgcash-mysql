web: export SECRET_KEY_BASE=`bundle exec rake secret` && rake db:create -e production && rake db:migrate -e production && bundle exec rails server thin -p 8080 -e production
