source 'https://rubygems.org'
ruby '2.5.0'

gem 'thin'
gem 'rails', '5.2.4.4'

gem 'rails_12factor'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'mimemagic', github: 'mimemagicrb/mimemagic', ref: '01f92d86d15d85cfd0f20dabd025dcbd36a8a60f'
gem 'mysql2', '~> 0.4.4'
gem 'sorcery', '~> 0.16.1'
gem 'json', '~> 1.8.2'
gem 'execjs'
gem 'rabl'
gem 'mechanize'
gem 'oj'
gem 'will_paginate', '~> 3.1.7
'
gem "figaro"
gem "foreman"
gem 'yaml_db', '~> 0.7.0'
gem 'whenever', require: false

# Gems used only for assets and not required
# in production environments by default.
#group :assets do
gem 'railties', "~> 5.2.3"
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
#end

gem 'jquery-rails'
gem "best_in_place", '~> 3.0.1'

gem 'gon'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :development, :test do
  gem 'rspec-rails', '~> 4.0.0'
  gem 'faker'
  gem 'rails-controller-testing'
  gem 'simplecov', :require => false
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
  gem "minitest"
  gem 'capybara', '~> 3.2'
  gem 'fabrication'
end
