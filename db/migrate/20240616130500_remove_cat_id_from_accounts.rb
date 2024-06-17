class RemoveCatIdFromAccounts < ActiveRecord::Migration[6.0]
  def up
    remove_column :accounts, :cat_id
  end

  def down
    add_column :accounts, :cat_id, :integer
  end
end