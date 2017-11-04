class LoadUserAccounts < ActiveRecord::Migration[4.2]
  def change

    # Make all accounts available to user 1
    Account.connection.execute('INSERT INTO accounts_users (account_id, user_id)
      SELECT id, 1
      FROM accounts WHERE id not in (select account_id from accounts_users)')

  end
end
