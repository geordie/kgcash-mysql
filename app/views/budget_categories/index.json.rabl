collection @budget_categories, :object_root => false
attributes :id => :id, :amount => :amount, :period => :period, :catogory_id => :category_id

glue :category do
	attributes :name => :category
	node :type do |u|
		u.cat_type.nil? ? "Expense" : u.cat_type
	end
end