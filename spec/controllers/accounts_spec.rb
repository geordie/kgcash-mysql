require "spec_helper"

RSpec.describe AccountsController, :type => :controller do
	include Sorcery::TestHelpers::Rails::Integration
	include Sorcery::TestHelpers::Rails::Controller

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

		it "loads @accounts" do

			tx_amount = get_tx_amount()

			# Add an expense transaction
			Fabricate(:transaction,
				user_id: @user.id,
				acct_id_cr: @acct_asset.id,
				credit: tx_amount,
				acct_id_dr: @acct_expense.id,
				debit: tx_amount
			)

			# Add an expense transaction
			Fabricate(:transaction,
				user_id: @user.id,
				acct_id_cr: @acct_asset.id,
				credit: tx_amount + 1.01,
				acct_id_dr: @acct_expense.id,
				debit: tx_amount + 1.01
			)

			get :index

			expect(response.status).to eq(200)
			expect(assigns(:accounts_array).count).to eq(@user.accounts.importable.count)

		end
	end

	describe 'GET #show' do

		it 'responds with 200' do

			acct_id = @user.accounts[0].id

			get :show, params: { id: acct_id }

			expect(response.status).to eq(200)
		end
	end

	describe 'GET #edit' do

		it 'Gets the right account for editing' do

			acct_id = @user.accounts[0].id

			get :edit, params: { id: acct_id }

			expect(assigns(:account).id).to eq(acct_id)
			expect(response.status).to eq(200)
		end
	end

	describe 'GET #create' do

		it 'should create a new account' do

			acct_name = "Cheque Acct"
			@account = {"name" => acct_name, "import_class" => "Vancity"}

			expect{post :create, params: {account: @account}}.to change(Account, :count).by(1)

			expect(assigns(:account).name).to eq(acct_name)
			expect(response.status).to eq(302)
		end
	end
end