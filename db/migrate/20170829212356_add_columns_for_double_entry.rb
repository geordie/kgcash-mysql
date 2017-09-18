class AddColumnsForDoubleEntry < ActiveRecord::Migration[4.2]
  def change
    add_column :accounts, :cat_id, :integer
    add_column :accounts, :import_class, :string
    add_column :transactions, :acct_id_cr, :integer
    add_column :transactions, :acct_id_dr, :integer
  end
end
