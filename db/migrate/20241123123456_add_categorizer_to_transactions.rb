class AddCategorizerToTransactions < ActiveRecord::Migration[6.1]
  def change
    add_column :transactions, :dr_categorizer, :string, default: nil
    add_column :transactions, :cr_categorizer, :string, default: nil
    add_index :transactions, :dr_categorizer
    add_index :transactions, :cr_categorizer
  end
end