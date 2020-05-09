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
			t1 = Transaction.create!(
				:tx_date => DateTime.now, 
				:user_id => @user.id,
				:debit => 1.2
			)

			t2 = Transaction.create!(
				:tx_date => DateTime.now,
				:user_id => @user.id,
				:debit => 3.4
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
