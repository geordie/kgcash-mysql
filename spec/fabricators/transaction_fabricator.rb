Fabricator(:transaction, :class_name => "Transaction") do
	id { sequence }
	tx_date { DateTime.now }
end