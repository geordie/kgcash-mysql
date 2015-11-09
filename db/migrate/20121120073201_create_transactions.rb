class CreateTransactions < ActiveRecord::Migration
  def change
    create_table :transactions do |t|
      t.string :tx_hash
      t.datetime :tx_date
      t.decimal  :debit,       :precision => 12, :scale => 2
      t.decimal  :credit,      :precision => 12, :scale => 2
      t.string :tx_type
      t.string :details
      t.string :notes
      t.references :category
      t.references :user

      t.timestamps
    end
    add_index :transactions, :category_id
    add_index :transactions, :user_id
  end
end
