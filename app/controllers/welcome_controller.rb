class WelcomeController < ApplicationController

	def index

		@user = current_user
		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		# Get expenses
		expenses = Transaction.expenses_all_time(@user,@year)
		@expenses = 0

		if !expenses.nil? && expenses.length > 0
			@expenses = expenses[0][:expenses].nil? ?
				0 : expenses[0][:expenses]
		end

		# Get revenues
		revenues = Transaction.revenues_all_time(@user,@year)
		@revenue = 0

		if !revenues.nil? && revenues.length > 0
			@revenue = revenues[0][:revenue].nil? ?
				0 : revenues[0][:revenue]
		end

		# Get uncategorized expenses
		expenses_uncategorized = Transaction.uncategorized_expenses(@user, @year)

		@expenses_uncategorized_amount = 0
		@expenses_uncategorized_count = 0
		if !expenses_uncategorized.nil? && expenses_uncategorized.length > 0
			@expenses_uncategorized_amount =
				expenses_uncategorized[0][:uncategorized_expenses]
			@expenses_uncategorized_count =
				expenses_uncategorized[0][:count]
		end

		# Get uncategorized revenue
		revenues_uncategorized = Transaction.uncategorized_revenue(@user, @year)

		@revenues_uncategorized_amount = 0
		@revenues_uncategorized_count = 0
		if !revenues_uncategorized.nil? && revenues_uncategorized.length > 0
			@revenues_uncategorized_amount =
				revenues_uncategorized[0][:uncategorized_revenue]
			@revenues_uncategorized_count =
				revenues_uncategorized[0][:count]
		end

		@net_income = (@revenue + @revenues_uncategorized_amount) -
			(@expenses + @expenses_uncategorized_amount)

		respond_to do |format|
			format.html #index.html.erb
		end

		# Get a breakdown of spending by spending instrument
		@spending_accounts = Transaction.expenses_by_spending_account(@user, @year)
	end

end
