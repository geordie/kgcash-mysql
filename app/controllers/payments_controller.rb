class PaymentsController < ApplicationController
	include TransactionControllerConcern

	helper_method :sort_column, :sort_direction

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		sJoinsAccounts = "LEFT JOIN accounts as accts_dr ON accts_dr.id = transactions.acct_id_dr"

		@pagy, @transactions = pagy(@user.transactions
			.joins(sJoinsAccounts)
			.select("transactions.id, tx_date, credit, debit, debit as 'amount', tx_type, details, notes, "\
				"acct_id_cr, acct_id_dr, parent_id, "\
				"(SELECT COUNT(*) from active_storage_attachments A WHERE A.record_id = transactions.id AND A.record_type = 'Transaction' and A.name = 'attachment' ) as attachments"
			)
			.is_payment()
			.where("(acct_id_cr IS NULL or acct_id_cr not in (select id from accounts where account_type = 'Liability'))")
			.in_year(@year)
			.order(sort_column + ' ' + sort_direction))

		respond_to do |format|
			format.html #index.html.erb
			format.csv {}
		end
	end
end
