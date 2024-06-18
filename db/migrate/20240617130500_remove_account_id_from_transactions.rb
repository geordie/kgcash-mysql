class RemoveAccountIdFromTransactions < ActiveRecord::Migration[6.0]
  def up
    remove_index :transactions, :account_id if index_exists?(:transactions, :account_id)
    remove_column :transactions, :account_id
  end

  def down
    add_column :transactions, :account_id, :integer
    add_index :transactions, :account_id
  end
end