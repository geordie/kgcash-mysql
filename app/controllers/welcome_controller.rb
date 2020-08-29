class WelcomeController < ApplicationController

	def index

		@user = current_user
		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		@transactions_expenses = Transaction.uncategorized_expenses(@user, @year)

		@transactions_revenues = Transaction.uncategorized_revenue(@user, @year)

		respond_to do |format|
			format.html #index.html.erb
		end
	end

end
