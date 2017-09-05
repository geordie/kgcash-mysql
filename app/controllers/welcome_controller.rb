class WelcomeController < ApplicationController

	def index

		@user = current_user

		@month = params.has_key?(:month) ? params[:month].to_i : nil
		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		@accounts = @user.accounts

		@transactions_expenses = @user.transactions
			.select("count(*) as count, sum(credit) as sum")
			.joins("INNER JOIN accounts A on A.id = acct_id_cr and A.account_type = 'Asset'")
			.where( "acct_id_dr IS NULL")

		@transactions_revenues = @user.transactions
			.select("count(*) as count, sum(debit) as sum")
			.joins("INNER JOIN accounts A on A.id = acct_id_dr and A.account_type = 'Asset'")
			.where( "acct_id_cr IS NULL")

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @accounts }
		end
	end

end
