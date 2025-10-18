require "spec_helper"

RSpec.describe TransactionsController, :type => :controller do
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

		it "loads @transactions" do
			tx_amount = get_tx_amount()

			# Add transactions
			Fabricate(:transaction,
				user: @user,
				tx_date: DateTime.now,
				credit: tx_amount,
				debit: tx_amount
			)

			Fabricate(:transaction,
				user: @user,
				tx_date: DateTime.now,
				credit: tx_amount + 2,
				debit: tx_amount + 2
			)

			get :index

			expect(response.status).to eq(200)
			expect(assigns(:transactions).size).to(eq(2))

		end
	end

	describe 'GET #new' do
		it 'returns a success response' do
			get :new
			expect(response).to have_http_status(:success)
		end
	end

	describe 'GET #edit' do

		it 'responds with 200' do

			tx_amount = get_tx_amount()

			# Add a transaction
			tx = Fabricate(:transaction,
				user: @user,
				credit: tx_amount,
				debit: tx_amount
			)

			get :edit, params: { id: tx.id }

			expect(assigns(:transaction).id).to eq(tx.id)
			expect(response).to have_http_status(:success)
		end
	end

	describe 'GET #create' do

		it 'should create a new transaction' do

			tx_amount = get_tx_amount()

			@new_tx = {
				"user_id" => @user.id,
				"tx_date" => DateTime.now,
				"details" => DateTime.now.to_s,
				"acct_id_cr" => nil,
				"credit" => nil,
				"acct_id_dr" => @acct_expense.id,
				"debit" => tx_amount
			}

			expect{post :create, params: {transaction: @new_tx}}.to change(Transaction, :count).by(1)

			expect(assigns(:transaction).debit).to eq(tx_amount)
			expect(response.status).to eq(302)
		end
	end

	describe 'GET #uncategorized' do

		it 'loads the right number of uncategorized transactions' do
			tx_amount = get_tx_amount()

			# Add an uncategorized expense
			Fabricate(:transaction,
				user: @user,
				acct_id_cr: @acct_asset.id,
				credit: tx_amount,
				acct_id_dr: nil,
				debit: tx_amount
			)

			# Add a categorized expense
			Fabricate(:transaction,
				user: @user,
				acct_id_cr: @acct_asset.id,
				credit: tx_amount + 1,
				acct_id_dr: @acct_expense.id,
				debit: tx_amount +1
			)

			get :uncategorized

			expect(response.status).to eq(200)
			expect(assigns(:transactions).length).to eq 1
		end

	end
end