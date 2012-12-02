require 'spec_helper'

describe "Transactions" do
  let!(:user) { Fabricate(:user) }

  before(:each) do
    response = user_login("admin", "admin")
  end

  describe "POST transaction" do

    it "should add a transaction via REST" do
      #TODO - Post a transaction via JSON
      
      #page.driver.post(user_sessions_url, { username: user, password: password})

      #site = RestClient::Resource.new('http://localhost:3000')
      #response = site['user_sessions/new'].post :params => {:username => 'admin', :password => 'admin'}
      
      #response = site['transactions'].get
      #puts response

      #page.driver.status_code.should eql 200
      #visit '/static_pages/home'
      #page.should have_content('Sample App')

      # rest_client approach
      #puts transactions_path
      #response = RestClient.get 'http://localhost:3000' + transactions_path
      #puts response.code
      #response.code eql 200
    end
  end
  
end