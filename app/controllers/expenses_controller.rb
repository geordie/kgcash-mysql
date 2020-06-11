class ExpensesController < ApplicationController
	include TransactionControllerConcern

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@month = params.has_key?(:month) ? params[:month].to_i : nil
		@category = params.has_key?(:category) ? params[:category].to_i : nil
		account = params.has_key?(:account) ? params[:account].to_i : nil

		sJoinsAccounts = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"

		@transactions = @user.transactions
			.joins(sJoinsAccounts)
			.select("transactions.id, tx_date, credit, debit, tx_type, details, notes, acct_id_cr, acct_id_dr, "\
			"IF(accts_cr.account_type = 'Expense', false, true) as is_expense "\
			)
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
				"AND acct_id_cr in (select id from accounts where account_type = 'Expense')) "\
					"OR "\
				"(acct_id_cr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
				"AND acct_id_dr in (select id from accounts where account_type = 'Expense'))")
			.in_account( @category )
			.in_month_year(@month, @year)
			.paginate(:page => params[:page])
			.order(sort_column + ' ' + sort_direction)

		@monthPrev, @yearPrev = DateMath.last_month( @month, @year )
		@monthNext, @yearNext = DateMath.next_month( @month, @year )

		respond_to do |format|
			format.html #index.html.erb
			format.csv {}
		end
	end

	def uncategorized
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		@transactions = @user.transactions
			.select("id, tx_date, credit, debit, tx_type, details, notes, acct_id_cr, acct_id_dr, 1 as 'is_expense'")
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

	def split
		@id = params.has_key?(:id) ? params[:id].to_i : 0

		@user = current_user

		@transaction = @user.transactions.find(params[:id])
		@accounts = @user.account_selector

		@transaction_new = @user.transactions.new()
		@transaction_new.tx_date = @transaction.tx_date
		@transaction_new.posting_date = @transaction.posting_date
		@transaction_new.tx_type = @transaction.tx_type
		@transaction_new.details = @transaction.details
		@transaction_new.notes = @transaction.notes
		@transaction_new.debit = 0
		@transaction_new.credit = 0
		@transaction_new.acct_id_cr = @transaction.acct_id_cr
		@transaction_new.acct_id_dr = @transaction.acct_id_dr


		respond_to do |format|
			format.html
		end
	end

	def update
		split_update
	end

	def split_update
		user = current_user
		tx_id = params[:transaction][:id]
		
		# Set debit to credit
		params[:transaction][:debit] = params[:transaction][:credit]
		success = false
		if tx_id.present?
			@transaction = user.transactions.find(tx_id)
			success = @transaction.update_attributes(expense_params)
		else
			@transaction = user.transactions.create(params[:transaction].permit(:name, :description, :account_type, :year, :id, :credit, :acct_id_dr, :tx_type, :details, :notes, :acct_id_cr, :tx_date, :posting_date))	
		end
		
		respond_to do |format|
			format.js { success }
			format.html { success }
			format.json { render json: @transaction.errors, status: :unprocessable_entity }
		end
	end

	private

	def expense_params
		params.require(:transaction).permit(:name, :description, :account_type, :year, :id, :credit, :debit, :acct_id_dr, :tx_type, :details, :notes, :acct_id_cr, :tx_date, :posting_date)
	end

end
