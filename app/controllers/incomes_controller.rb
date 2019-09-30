class IncomesController < ApplicationController
	include TransactionControllerConcern

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@month = params.has_key?(:month) ? params[:month].to_i : nil
		category = params.has_key?(:category) ? params[:category].to_i : nil

		@transactions = @user.transactions
			.select("id, tx_date, credit, debit, tx_type, details, notes, acct_id_cr, acct_id_dr")
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset') "\
			"AND acct_id_cr in (select id from accounts where account_type = 'Income')) "\
				"OR "\
			"(acct_id_cr in (select id from accounts where account_type = 'Asset') "\
			"AND acct_id_dr in (select id from accounts where account_type = 'Income'))")
			.in_account( category )
			.in_month_year(@month, @year)
			.paginate(:page => params[:page])
			.order(sort_column + ' ' + sort_direction)

		respond_to do |format|
			format.html #index.html.erb
			format.csv {}
		end
	end

	def uncategorized
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		@transactions = @user.transactions
			.select("id, tx_date, credit, debit, tx_type, details, notes, acct_id_cr, acct_id_dr")
			.is_liability()
			.where("(acct_id_cr IS NULL)")
			.in_year(@year)
			.paginate(:page => params[:page])
			.order(sort_column + ' ' + sort_direction)

		respond_to do |format|
			format.html #index.html.erb
			format.csv {}
		end
	end

	private

	def expense_params
		params.require(:income).permit(:name, :description, :account_type)
	end

end
