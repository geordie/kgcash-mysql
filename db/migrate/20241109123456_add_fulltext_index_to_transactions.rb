class AddFulltextIndexToTransactions < ActiveRecord::Migration[6.0]
  def change
    # Add a full-text index on the details and notes columns
    execute <<-SQL
      ALTER TABLE transactions
      ADD FULLTEXT INDEX fulltext_index_details_notes (details, notes);
    SQL
  end
end