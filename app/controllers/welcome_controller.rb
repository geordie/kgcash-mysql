class WelcomeController < ApplicationController

	def index

		@user = current_user
		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		@expenses_uncategorized = Transaction.uncategorized_expenses(@user, @year)
		@revenues_uncategorized = Transaction.uncategorized_revenue(@user, @year)

		# expenses_all_time

		respond_to do |format|
			format.html #index.html.erb
		end
	end

end
