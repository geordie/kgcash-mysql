class ExpensesController < ApplicationController

	helper_method :sort_column, :sort_direction

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		@transactions = @user.transactions
			.select("id, tx_date, credit, debit, tx_type, details, notes, acct_id_cr, acct_id_dr")
			.is_expense()
			.where("(acct_id_dr IS NULL or acct_id_dr in (select id from accounts where account_type = 'Expense'))")
			.in_year(@year)
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
			.is_expense()
			.where("(acct_id_dr IS NULL)")
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
		params.require(:expense).permit(:name, :description, :account_type, :year)
	end

	def sort_column
		['tx_date','account','details','notes','amount'].include?(params[:sort]) ? params[:sort] : "tx_date"
	end

	def sort_direction
		%w[asc desc].include?(params[:direction]) ?  params[:direction] : "desc"
	end

end
