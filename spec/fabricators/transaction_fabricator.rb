Fabricator(:transaction, :class_name => "Transaction") do
	user
	tx_date { DateTime.now }
end