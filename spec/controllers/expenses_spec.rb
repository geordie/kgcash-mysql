require "spec_helper"

RSpec.describe ExpensesController, :type => :controller do
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
			expect(response.status).to eq(200)
		end

		it "loads the right number of expense @transactions" do

			tx_amount = get_tx_amount()

			# Add an expense transaction
			Fabricate(:transaction,
				user_id: @user.id,
				acct_id_cr: @acct_expense.id,
				credit: tx_amount,
				acct_id_dr: @acct_asset.id,
				debit: tx_amount
			)

			# Add a revenue transaction
			Fabricate(:transaction,
				user_id: @user.id,
				acct_id_cr: @acct_income.id,
				credit: tx_amount + 2,
				acct_id_dr: @acct_asset.id,
				debit: tx_amount + 2,
			)

			get :index

			expect(response.status).to eq(200)

			# Expect 1 since one of the added transactions is not an expense
			expect(assigns(:transactions).count).to eq 1
		end
	end

	describe 'GET #show' do
	  let(:token) { double :accessible? => true }

      it 'responds with 200' do
        get :index
        expect(response.status).to eq(200)
      end
    end
end
