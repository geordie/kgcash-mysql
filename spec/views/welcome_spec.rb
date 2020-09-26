require "spec_helper"

describe "welcome/index.html.erb", type: :view do
  it "displays the welcome page" do
    assign( :year, 2020 )
    assign( :expenses_uncategorized_amount, 323 )
    assign( :expenses_uncategorized_count, 5 )
    assign( :revenues_uncategorized_amount, 24376 )
    assign( :revenues_uncategorized_count, 6 )
    
    render

    expect(rendered).to match(/24376/)
  end
end