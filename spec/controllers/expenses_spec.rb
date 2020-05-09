require "spec_helper"

RSpec.describe ExpensesController, :type => :controller do
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
			get :index

			expect(response.status).to eq(200)
			# Expect 0 since the added transaction is not an expense
			expect(assigns(:transactions).count).to eq(0)
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
