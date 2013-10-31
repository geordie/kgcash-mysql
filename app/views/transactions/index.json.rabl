collection @transactions, :object_root => false
attributes :tx_date => :date

node :amount do |t|
	@amount = (t.credit.nil? ? 0 : t.credit) - t.debit
end

glue :category do
	attributes :name => :category
	node :type do |u|
		u.cat_type.nil? ? "Expense" : u.cat_type
	end
end