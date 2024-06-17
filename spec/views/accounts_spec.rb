require "spec_helper"

describe "accounts/spending.html.erb", type: :view do
  it "displays the accounts index page" do
	assign( :year, Date.today.year )
	
    assign( :accounts_array, Array.new(0) )
    
    render

    expect(rendered).to match(/My Spending Accounts/)
  end
end

describe "accounts/index.html.erb", type: :view do
  it "displays accounts index page that shows all ccounts" do
	assign( :year, Date.today.year )

    assign( :expenseAccounts, Array.new(0) )

    render

    expect(rendered).to match(/My Accounts/)
  end
end