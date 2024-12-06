class AddCategorizerToTransactions < ActiveRecord::Migration[6.1]
  def change
    add_column :transactions, :acct_id_cr_proposed, :string, default: nil
    add_column :transactions, :acct_id_dr_proposed, :string, default: nil
    add_column :transactions, :acct_id_cr_proposed_source, :string, default: nil
    add_column :transactions, :acct_id_dr_proposed_source, :string, default: nil
    add_index :transactions, :acct_id_cr_proposed_source
    add_index :transactions, :acct_id_dr_proposed_source
  end
end