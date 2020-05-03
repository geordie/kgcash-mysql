require "spec_helper"

describe "accounts/index.html.erb", type: :view do
  it "displays the accounts index page" do
	assign( :year, 2020 )
	
    assign( :accounts_array, Array.new(0) )
    
    render

    expect(rendered).to match(/My Accounts/)
  end
end