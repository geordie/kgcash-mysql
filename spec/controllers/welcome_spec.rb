require "spec_helper"

RSpec.describe WelcomeController, :type => :controller do
	include Sorcery::TestHelpers::Rails::Integration
	include Sorcery::TestHelpers::Rails::Controller

	before :each do
		@user = Fabricate(:user)
		login_user
	end

	describe 'GET #index' do

		it "loads default variables" do

			dateNow = DateTime.now

			get :index

			expect(response.status).to eq(200)
			expect(assigns(:year)).to eq(dateNow.year)
			expect(assigns(:month)).to eq(nil)

		end
	end

end