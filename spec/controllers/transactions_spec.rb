require "spec_helper"

RSpec.describe TransactionsController, :type => :controller do

	before :each do
		controller.stub(:doorkeeper_token) { token }
		request.env["HTTP_ACCEPT"] = 'application/json'
	end

	describe 'GET #index' do
		let!(:user) { Fabricate(:user) }
		let(:token) { double :accessible? => true }


		it 'responds with 200' do
			get :index
			response.status.should eq(200)
		end

		it "loads @transactions" do
			t1 = Transaction.create!(:tx_date => Date.new(2016,1,1), :user_id => user.id)
			t2 = Transaction.create!(:tx_date => Date.new(2016,1,2), :user_id => user.id)

			get :index
			expect(assigns(:transactions)).to match_array([t1, t2])
		end
	end

	describe 'GET #show' do
	  let!(:user) { Fabricate(:user) }
	  let(:token) { double :accessible? => true }

      it 'responds with 200' do
        get :index
        response.status.should eq(200)
      end
    end
end
