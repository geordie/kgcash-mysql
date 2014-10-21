collection @budget_categories, :object_root => false
attributes :id => :id, :amount => :amount, :period => :period, :category_id => :category_id

glue :category do
	attributes :name => :category_name
	node :type do |u|
		u.cat_type.nil? ? "Expense" : u.cat_type
	end
end