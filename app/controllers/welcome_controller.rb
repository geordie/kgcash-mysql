class WelcomeController < ApplicationController

	def index

		@user = current_user

		@month = params.has_key?(:month) ? params[:month].to_i : nil
		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		@accounts = @user.accounts

		@transactions_expenses = @user.transactions
			.select("count(*) as count, sum(credit) as sum")
			.is_expense()
			.where("(acct_id_dr IS NULL)")
			.in_year(@year)

		@transactions_revenues = @user.transactions
			.select("count(*) as count, sum(debit) as sum")
			.is_liability()
			.where("(acct_id_cr IS NULL)")
			.in_year(@year)

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @accounts }
		end
	end

end
