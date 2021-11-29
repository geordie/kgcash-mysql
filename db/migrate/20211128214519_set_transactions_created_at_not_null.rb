class SetTransactionsCreatedAtNotNull < ActiveRecord::Migration[4.2]
  def change
    Transaction.where(created_at: nil).each do |tx|
      tx.created_at = tx.tx_date
    	tx.save();
    end

    Transaction.where(updated_at: nil).each do |tx|
      tx.updated_at = Time.now
    	tx.save();
    end

    change_column_null :transactions, :created_at, false
    change_column_null :transactions, :updated_at, false
  end
end
