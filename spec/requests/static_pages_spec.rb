require 'spec_helper'

describe "Static pages" do

  describe "Home page" do
    it "should have the content 'Welcome'" do
      visit '/'
      expect(page).to have_content("flows")
    end
  end

end
