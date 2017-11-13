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
			t1 = Transaction.create!(:tx_date => Date.new(2016,1,1), :user_id => @user.id)
			t2 = Transaction.create!(:tx_date => Date.new(2016,1,2), :user_id => @user.id)

			get :index
			expect(response.status).to eq(200)
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
