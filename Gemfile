source 'https://rubygems.org'
ruby '2.5.9'

gem 'thin'
gem 'rails', '5.2.4.6'

gem 'rails_12factor'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem "google-cloud-storage", "~> 1.8", require: false
gem 'mimemagic', github: 'mimemagicrb/mimemagic', ref: '01f92d86d15d85cfd0f20dabd025dcbd36a8a60f'
gem 'mysql2', '~> 0.4.4'
gem 'sorcery', '~> 0.16.1'
gem 'json', '~> 2.3'
gem 'execjs'
gem 'rabl'
gem 'mechanize', '~> 2.8'
gem 'oj'
gem 'will_paginate', '~> 3.1.7
'
gem "figaro"
gem "foreman"
gem 'yaml_db', '~> 0.7.0'

# Gems used only for assets and not required
# in production environments by default.
#group :assets do
gem 'railties', "~> 5.2.3"
gem 'sassc-rails'
gem 'coffee-rails'
gem 'uglifier'
#end

gem 'jquery-rails'
gem "best_in_place", '~> 3.0.1'

gem 'gon'

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
