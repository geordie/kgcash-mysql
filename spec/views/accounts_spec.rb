require "spec_helper"

describe "accounts/index.html.erb", type: :view do
  it "displays the accounts index page" do
	assign( :year, Date.today.year )
	
    assign( :accounts_array, Array.new(0) )
    assign( :allAccounts, Array.new(0) )
    
    render

    expect(rendered).to match(/My Spending Accounts/)
  end
end