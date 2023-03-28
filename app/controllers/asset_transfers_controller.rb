class AssetTransfersController < ApplicationController
	include TransactionControllerConcern

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@month = params.has_key?(:month) ? params[:month].to_i : nil
		category = params.has_key?(:category) ? params[:category].to_i : nil

		sJoinsIncome = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"

		@transactions = @user.transactions
			.joins(sJoinsIncome)
			.select("transactions.id, tx_date, credit, debit, debit as 'amount', tx_type, details, notes, acct_id_cr, acct_id_dr, parent_id, " \
			"IF(accts_cr.import_class IS NOT NULL, 'credit', 'debit') as txType "\
			)
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset') "\
			"AND acct_id_cr in (select id from accounts where account_type = 'Asset')) ")
			.in_account( category )
			.in_month_year(@month, @year)
			#.paginate(:page => params[:page])
			.order(sort_column + ' ' + sort_direction)

		respond_to do |format|
			format.html #index.html.erb
			format.csv {}
		end
	end
end
