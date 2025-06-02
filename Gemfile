source 'https://rubygems.org'
ruby '3.2.5'

gem 'thin'
gem 'rails', '7.2.2.1'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem "google-cloud-storage", "~> 1.8", require: false
gem 'mysql2', '~> 0.5.3'
gem 'sorcery', '~> 0.17'
gem 'json', '~> 2.3'
gem 'prawn', '>= 2.4.0'
gem 'execjs'
gem 'oj'
gem 'nokogiri', '>= 1.18.4'
gem "foreman"
gem 'yaml_db', '~> 0.7.0'
gem 'pagy', '>= 9.3' # omit patch digit
gem "sprockets-rails"

# Gems used only for assets and not required
# in production environments by default.
#group :assets do
gem 'railties', ">= 6.1.7.7"
gem 'sassc-rails'
gem 'coffee-rails'
gem 'uglifier'
#end

gem 'jquery-rails'
# gem "best_in_place", git: "https://github.com/mmotherwell/best_in_place"
gem 'best_in_place', '~> 4.0'

gem 'gon'

group :development, :test do
  gem 'rspec-rails', '>= 4.2'
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
