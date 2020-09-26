class WelcomeController < ApplicationController

	def index

		@user = current_user
		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		expenses = Transaction.expenses_all_time(@user,@year)
		@expenses = 0

		if !expenses.nil? && expenses.length > 0
			@expenses = expenses[0][:expenses].nil? ?
				0 : expenses[0][:expenses]
		end

		revenues = Transaction.revenues_all_time(@user,@year)
		@revenue = 0

		if !revenues.nil? && revenues.length > 0
			@revenue = revenues[0][:revenue].nil? ?
				0 : revenues[0][:revenue]
		end

		@expenses_uncategorized = Transaction.uncategorized_expenses(@user, @year)
		@revenues_uncategorized = Transaction.uncategorized_revenue(@user, @year)

		respond_to do |format|
			format.html #index.html.erb
		end
	end

end
