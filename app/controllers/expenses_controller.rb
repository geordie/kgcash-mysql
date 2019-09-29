class ExpensesController < ApplicationController
	include TransactionControllerConcern

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@month = params.has_key?(:month) ? params[:month].to_i : nil
		category = params.has_key?(:category) ? params[:category].to_i : nil
		account = params.has_key?(:account) ? params[:account].to_i : nil

		@transactions = @user.transactions
			.select("id, tx_date, credit, debit, tx_type, details, notes, acct_id_cr, acct_id_dr")
			.is_expense()
			.where("(acct_id_dr IS NULL or acct_id_dr in (select id from accounts where account_type = 'Expense'))")
			.in_debit_acct( category )
			.in_credit_acct( account )
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
		
		success = false
		if tx_id.present?

			@transaction = user.transactions.find(tx_id)
			success = @transaction.update_attributes(expense_params)
		else
			@transaction = user.transactions.create(params[:transaction].permit(:name, :description, :account_type, :year, :id, :credit, :acct_id_dr, :tx_type, :details, :notes, :acct_id_cr, :tx_date, :posting_date))	
		end
		
		respond_to do |format|
			format.js { success }
			format.html { render action: "edit" }
			format.json { render json: @transaction.errors, status: :unprocessable_entity }
		end
	end

	private

	def expense_params
		params.require(:transaction).permit(:name, :description, :account_type, :year, :id, :credit, :acct_id_dr, :tx_type, :details, :notes, :acct_id_cr, :tx_date, :posting_date)
	end

end
