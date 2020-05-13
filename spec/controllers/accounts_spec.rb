require "spec_helper"

RSpec.describe AccountsController, :type => :controller do
	include Sorcery::TestHelpers::Rails::Integration
	include Sorcery::TestHelpers::Rails::Controller
	#let!(:user) { Fabricate(:user) }

	before :each do
		@user = Fabricate(:user)
		login_user
	end

	describe 'GET #index' do

		it "loads @accounts" do

			get :index

			expect(response.status).to eq(200)
			expect(assigns(:accounts_array).count).to eq(@user.accounts.importable.count)

		end
	end

	describe 'GET #show' do

		it 'responds with 200' do

			get :index

			expect(response.status).to eq(200)
		end
	end

	describe 'GET #edit' do

		it 'responds with 200' do

			acct_id = @user.accounts[0].id

			get :edit, params: { id: acct_id }

			expect(assigns(:account).id).to eq(acct_id)
			expect(response.status).to eq(200)
		end
	end
end