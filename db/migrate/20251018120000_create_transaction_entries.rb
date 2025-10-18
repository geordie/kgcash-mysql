class CreateTransactionEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :transaction_entries, id: :integer do |t|
      t.integer :transaction_id, null: false
      t.integer :account_id, null: false
      t.decimal :debit_amount, precision: 12, scale: 2
      t.decimal :credit_amount, precision: 12, scale: 2
      t.text :memo

      t.timestamps

      # Ensure exactly one of debit or credit is present (XOR constraint)
      t.check_constraint "(debit_amount IS NOT NULL AND credit_amount IS NULL) OR (debit_amount IS NULL AND credit_amount IS NOT NULL)",
        name: 'one_amount_required'

      # Ensure amounts are positive (or null)
      t.check_constraint "debit_amount IS NULL OR debit_amount >= 0",
        name: 'debit_non_negative'
      t.check_constraint "credit_amount IS NULL OR credit_amount >= 0",
        name: 'credit_non_negative'
    end

    # Add foreign keys
    add_foreign_key :transaction_entries, :transactions
    add_foreign_key :transaction_entries, :accounts

    # Add indexes
    add_index :transaction_entries, :transaction_id
    add_index :transaction_entries, :account_id
    add_index :transaction_entries, [:transaction_id, :account_id],
      name: 'index_transaction_entries_on_transaction_and_account'

    # Add split tracking columns to transactions table (for audit trail)
    add_column :transactions, :split_at, :datetime,
      comment: 'Timestamp when transaction was split into multiple entries'
    add_column :transactions, :split_source_ids, :text,
      comment: 'JSON array of original child transaction IDs (for migration audit trail)'
  end
end
