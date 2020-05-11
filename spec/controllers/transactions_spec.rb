require "spec_helper"

RSpec.describe TransactionsController, :type => :controller do
	include Sorcery::TestHelpers::Rails::Integration
	include Sorcery::TestHelpers::Rails::Controller
	#let!(:user) { Fabricate(:user) }

	before :each do
		@user = Fabricate(:user)
		login_user
	end

	describe 'GET #index' do

		it 'responds with 200' do
			get :index
			expect(response.status).to eq(200)
		end

		it "loads @transactions" do
			tx_amount = rand(100) + rand()

			# Add transactions
			Fabricate(:transaction,
				user_id: @user.id,
				credit: tx_amount,
				debit: tx_amount
			)

			Fabricate(:transaction,
				user_id: @user.id,
				credit: tx_amount + 2,
				debit: tx_amount + 2
			)

			get :index

			expect(response.status).to eq(200)
			expect(assigns(:transactions).count).to eq(2)

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
