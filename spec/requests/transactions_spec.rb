require 'spec_helper'
require 'oauth2'

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

feature 'OAuth - manage transactions' do
  let!(:app) { Fabricate(:application) }
  let!(:user) { Fabricate(:user) }

  scenario 'auth ok' do
    client = OAuth2::Client.new(app.uid, app.secret) do |b|
      b.request :url_encoded
      b.adapter :rack, Rails.application
    end
    
    token = client.password.get_token(user.username, "admin")
    token.should_not be_expired
  end

  scenario 'get transactions' do
    client = OAuth2::Client.new(app.uid, app.secret) do |b|
      b.request :url_encoded
      b.adapter :rack, Rails.application
    end
    
    token = client.password.get_token(user.username, "admin")
    response = token.get("/transactions");
    #puts response.body
    response.status.should == 200 
  end


  scenario 'post a transaction' do
    client = OAuth2::Client.new(app.uid, app.secret) do |b|
      b.request :url_encoded
      b.adapter :rack, Rails.application
    end
    
    token = client.password.get_token(user.username, "admin")
    data = {:transaction => {:tx_date => "2012-12-11T06:16:14Z", :debit => 123.23, :credit => 340.22}}

    response = token.post("/transactions.json", :body=>data);
    response.status.should == 201 
  end

  scenario 'Can''t post two transactions with same hash' do
    client = OAuth2::Client.new(app.uid, app.secret) do |b|
      b.request :url_encoded
      b.adapter :rack, Rails.application
    end
    
    token = client.password.get_token(user.username, "admin")
    data = {:transaction => {:tx_date => "2012-12-11T06:15:14Z", :debit => 123.23, :credit => 340.22}}

    response = token.post("/transactions.json", :body=>data);
    response.status.should == 201 

    expect { token.post("/transactions.json", :body=>data) }.to raise_error( ActiveRecord::RecordNotUnique )

  end

end