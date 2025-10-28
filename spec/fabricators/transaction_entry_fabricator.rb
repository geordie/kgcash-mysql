Fabricator(:transaction_entry, class_name: "TransactionEntry") do
  parent_transaction(fabricator: :transaction)
  account
  debit_amount { nil }
  credit_amount { 100.00 }
end

Fabricator(:debit_entry, from: :transaction_entry) do
  debit_amount { 100.00 }
  credit_amount { nil }
end

Fabricator(:credit_entry, from: :transaction_entry) do
  debit_amount { nil }
  credit_amount { 100.00 }
end
