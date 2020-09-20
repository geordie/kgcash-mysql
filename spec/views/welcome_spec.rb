require "spec_helper"

describe "welcome/index.html.erb", type: :view do
  it "displays the welcome page" do
    assign( :year, 2020 )
    assign( :transactions_expenses, [{:count => 5, :uncategorized_expenses => 323}] )
    assign( :transactions_revenues, [{:count => 6, :uncategorized_revenue => 24376}] )
    
    render

    expect(rendered).to match(/24376/)
  end
end