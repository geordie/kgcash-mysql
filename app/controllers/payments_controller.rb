class PaymentsController < ApplicationController

	helper_method :sort_column, :sort_direction

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		sJoinsAccounts = "LEFT JOIN accounts as accts_dr ON accts_dr.id = transactions.acct_id_dr"

		@transactions = @user.transactions
			.joins(sJoinsAccounts)
			.select("transactions.id, tx_date, credit, debit, tx_type, details, notes, acct_id_cr, acct_id_dr, "\
				"IF(accts_dr.account_type = 'Liability', true, false) as is_credit ")
			.is_payment()
			.where("(acct_id_cr IS NULL or acct_id_cr not in (select id from accounts where account_type = 'Liability'))")
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

	def sort_column
		['tx_date','account','details','notes','amount'].include?(params[:sort]) ? params[:sort] : "tx_date"
	end

	def sort_direction
		%w[asc desc].include?(params[:direction]) ?  params[:direction] : "desc"
	end

end
