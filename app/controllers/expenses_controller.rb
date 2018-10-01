class ExpensesController < ApplicationController
	include TransactionControllerConcern

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		category = params.has_key?(:category) ? params[:category].to_i : nil
		account = params.has_key?(:account) ? params[:account].to_i : nil

		@transactions = @user.transactions
			.select("id, tx_date, credit, debit, tx_type, details, notes, acct_id_cr, acct_id_dr")
			.is_expense()
			.where("(acct_id_dr IS NULL or acct_id_dr in (select id from accounts where account_type = 'Expense'))")
			.in_debit_acct( category )
			.in_credit_acct( account )
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

end
