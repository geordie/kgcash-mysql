class ConvertAccountsToBelongToUser < ActiveRecord::Migration[7.0]
  def up
    # Add user_id to accounts table (using :integer to match users.id type)
    add_reference :accounts, :user, type: :integer, foreign_key: true, index: true

    # Migrate data from accounts_users to accounts.user_id
    # For accounts with multiple users, assign to the first user (shouldn't happen based on analysis)
    # For accounts with no users, leave user_id as NULL (will need cleanup)
    execute <<-SQL
      UPDATE accounts a
      INNER JOIN (
        SELECT account_id, MIN(user_id) as user_id
        FROM accounts_users
        GROUP BY account_id
      ) au ON a.id = au.account_id
      SET a.user_id = au.user_id
    SQL

    # Drop the join table
    drop_table :accounts_users
  end

  def down
    # Recreate the join table
    create_table :accounts_users do |t|
      t.integer :account_id
      t.integer :user_id
    end

    # Migrate data back from accounts.user_id to accounts_users
    execute <<-SQL
      INSERT INTO accounts_users (account_id, user_id)
      SELECT id, user_id
      FROM accounts
      WHERE user_id IS NOT NULL
    SQL

    # Remove user_id from accounts
    remove_reference :accounts, :user
  end
end
