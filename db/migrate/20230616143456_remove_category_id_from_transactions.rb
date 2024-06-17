class RemoveCategoryIdFromTransactions < ActiveRecord::Migration[6.0]
  def up
    remove_index :transactions, :category_id if index_exists?(:transactions, :category_id)
    remove_column :transactions, :category_id
  end

  def down
    add_column :transactions, :category_id, :integer
    add_index :transactions, :category_id
  end
end