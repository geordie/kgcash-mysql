# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'simplecov'


# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

SimpleCov.start do
	add_filter '/test/'
	add_filter '/config/'
	add_filter '/vendor/'

	add_group 'Controllers', 'app/controllers'
	add_group 'Models', 'app/models'
	add_group 'Helpers', 'app/helpers'
	add_group 'Mailers', 'app/mailers'
end
# This outputs the report to your public folder
# You will want to add this to .gitignore
SimpleCov.coverage_dir 'public/coverage'

RSpec.configure do |config|
	# ## Mock Framework
	#
	# If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
	#
	# config.mock_with :mocha
	# config.mock_with :flexmock
	# config.mock_with :rr

	# Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
	config.fixture_path = "#{::Rails.root}/spec/fixtures"

	# If you're not using ActiveRecord, or you'd prefer not to run each of your
	# examples within a transaction, remove the following line or assign false
	# instead of true.
	config.use_transactional_fixtures = true

	# If true, the base class of anonymous controllers will be inferred
	# automatically. This will be the default behavior in future versions of
	# rspec-rails.
	config.infer_base_class_for_anonymous_controllers = false

	# Run specs in random order to surface order dependencies. If you find an
	# order dependency and want to debug it, you can fix the order by providing
	# the seed, which is printed after each run.
	#     --seed 1234
	config.order = "random"

	config.include Sorcery::TestHelpers::Rails

	config.include Capybara::DSL
end


module Sorcery
	module TestHelpers
		module Rails

			def user_login(user, password)
				page.driver.post(user_sessions_url, { username: user, password: password})
			end

			def login_user(user, password)
				visit login_path

				fill_in 'email', with: user.email
				fill_in 'password', with: 'admin'
				click_button 'login'
			end

			def get_tx_amount()
				return rand(100) + (rand(100)/100)
			end

		end
	end
end
