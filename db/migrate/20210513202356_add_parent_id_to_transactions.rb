class AddParentIdToTransactions < ActiveRecord::Migration[4.2]
  def change
    add_column :transactions, :parent_id, :integer
  end
end
