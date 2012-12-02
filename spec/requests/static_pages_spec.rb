require 'spec_helper'

describe "Static pages" do
  let!(:user) { Fabricate(:user) }

  before(:each) do
    login_user_post("admin", "admin")
  end

  describe "Home page" do

    it "should have the content 'Sample App'" do
      visit '/static_pages/home'
      page.should have_content('Sample App')
    end
  end
end