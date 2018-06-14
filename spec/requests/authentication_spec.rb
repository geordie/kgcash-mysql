require 'spec_helper'

describe "Authentication", :type => :request do
  it 'allows users to log in' do
    user = Fabricate(:user)

    visit login_path
    expect(page).to have_content("Email")

    fill_in 'email', with: user.email
    fill_in 'password', with: 'admin'
    elem = click_button 'login'

    expect(page).to have_content("Login successful")
  end
# other examples ...
end
