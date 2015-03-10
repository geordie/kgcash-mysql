module TransactionsHelper
	def budget_categories_select(budgetDefault, category)
		# I assume folder.name should be a non-blank string
		# You should properly validate this in folder model
		select_tag( :category,
			options_from_collection_for_select(budgetDefault.sortedCategories,
			'id','name', category),:class => 'transaction_filter',
			:prompt => "All" ) if budgetDefault
	end

	def options_for_budget_categories(budgetDefault, category)
		options_from_collection_for_select(budgetDefault.sortedCategories,
			'id','name', category) if budgetDefault
	end
end

