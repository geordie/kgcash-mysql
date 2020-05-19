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