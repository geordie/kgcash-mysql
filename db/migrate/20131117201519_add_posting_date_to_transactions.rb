class AddPostingDateToTransactions < ActiveRecord::Migration[4.2]
  def change
    add_column :transactions, :posting_date, :datetime

    Transaction.all.each do |tx|
    	tx.posting_date = tx.tx_date
    	tx.save();
    end
  end
end
