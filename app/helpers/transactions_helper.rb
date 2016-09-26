module TransactionsHelper

	def options_for_budget_categories(budgetDefault, category)
		options_from_collection_for_select(budgetDefault.sortedCategories,
			'id','name', category) if budgetDefault
	end
end
