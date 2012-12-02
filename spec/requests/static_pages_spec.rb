require 'spec_helper'

describe "Static pages" do
  let!(:user) { Fabricate(:user) }

  before(:each) do
    user_login("admin", "admin")
  end

  describe "Home page" do
    it "should have the content 'Sample App'" do
      visit '/static_pages/home'
      page.should have_content('Sample App')
    end
  end

  describe "Home page" do
    it "should have the content 'Sample App'" do
      response = visit '/static_pages/home'
      puts page.html
      page.should have_content('Sample App')
    end
  end

end