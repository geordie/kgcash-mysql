require "spec_helper"

RSpec.describe IncomesController, :type => :controller do
	include Sorcery::TestHelpers::Rails::Integration
	include Sorcery::TestHelpers::Rails::Controller
	#let!(:user) { Fabricate(:user) }

	before :each do
		@user = Fabricate(:user)
		@acct_expense = nil
		@acct_asset = nil
		@acct_income = nil
		@user.accounts.each do |acct|
			if acct.account_type == "Expense"
				@acct_expense = acct
			elsif acct.account_type == "Asset"
				@acct_asset = acct
			elsif acct.account_type == "Income"
				@acct_income = acct
			end

			if !@acct_expense.nil? &&
				!@acct_asset.nil? &&
				!@acct_income.nil?

				break
			end
		end
		login_user
	end

	describe 'GET #index' do
		it 'responds with 200' do
			get :index
			expect(response).to have_http_status(:success)
		end
	end
end