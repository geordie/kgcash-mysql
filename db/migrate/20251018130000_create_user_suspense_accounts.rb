class CreateUserSuspenseAccounts < ActiveRecord::Migration[7.2]
  def up
    # Create suspense accounts for each existing user
    User.find_each do |user|
      create_suspense_accounts_for_user(user)
    end
  end

  def down
    # Remove all suspense accounts
    Account.where(
      name: ['Uncategorized Expenses', 'Uncategorized Income']
    ).destroy_all
  end

  private

  def create_suspense_accounts_for_user(user)
    # Create Uncategorized Expenses account
    unless user.accounts.exists?(name: 'Uncategorized Expenses')
      user.accounts.create!(
        name: 'Uncategorized Expenses',
        account_type: 'Expense',
        description: 'Temporary holding account for imported expenses awaiting categorization'
      )
    end

    # Create Uncategorized Income account
    unless user.accounts.exists?(name: 'Uncategorized Income')
      user.accounts.create!(
        name: 'Uncategorized Income',
        account_type: 'Income',
        description: 'Temporary holding account for imported income awaiting categorization'
      )
    end
  end
end
