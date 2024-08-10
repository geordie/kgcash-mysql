require "spec_helper"

RSpec.feature "Show incomes page", type: :feature do
  scenario "displays the incomes index page" do
    @user = Fabricate(:user)
    login_user(@user, @user.password)
    visit "/incomes"

    expect(page).to have_text("Income")
  end
end