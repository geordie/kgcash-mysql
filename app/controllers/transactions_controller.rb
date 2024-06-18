class TransactionsController < ApplicationController
	include TransactionControllerConcern

	def show

		@user = current_user
		if @user == nil
			@user = User.last
		end
		@transaction = @user.transactions.find(params[:id])

		sJoinsAccounts = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"

		@pagy, @transactions = pagy(@user.transactions
			.joins(sJoinsAccounts)
			.select("transactions.id, tx_date, credit, credit as 'amount', debit, tx_type, details, notes, acct_id_cr, acct_id_dr, parent_id, "\
			"IF(accts_cr.account_type = 'Expense', 'credit', 'debit') as txType, "\
			"(SELECT COUNT(*) from active_storage_attachments A WHERE A.record_id = transactions.id AND A.record_type = 'Transaction' and A.name = 'attachment' ) as attachments"
			)
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
				"AND acct_id_cr in (select id from accounts where account_type = 'Expense')) "\
					"OR "\
				"(acct_id_cr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
				"AND acct_id_dr in (select id from accounts where account_type = 'Expense'))")
			.where(parent_id: params[:id])
			.order(sort_column + ' ' + sort_direction))

		respond_to do |format|
			format.html #show.html.erb
			format.json {render json: @transaction}
		end
	end

	def edit
		@user = current_user
		@transaction = @user.transactions.find(params[:id])
		@accounts = @user.account_selector
	end

	def create
		@user = current_user

		@transaction = @user.transactions.create(transaction_params)

		respond_to do |format|
			if @transaction.save
				format.html { redirect_to(transactions_path, :notice => 'Transaction was successfully created for user.') }
				format.json { render json: @transaction, status: :created, location: @transaction }
			else
				format.html { render action: "new" }
				format.json { render json: @transaction.errors, status: :unprocessable_entity }
			end
		end
	end

	def update

		user = current_user
		@transaction = user.transactions.find(params[:id])

		respond_to do |format|
			if @transaction.update(transaction_params)
				format.html {  redirect_to transactions_path, notice: 'Transaction was successfully updated.' }
				format.json { respond_with_bip(@transaction) }
				format.js {
					redirect_to transactions_path
					# render :nothing => true, :status => 200, :content_type => 'text/html' 
				}
			else
				format.html { render action: "edit" }
				format.json { render json: @transaction.errors, status: :unprocessable_entity }
			end
		end
	end


	def new
		@user = current_user
		@dateTx = DateTime.now
		@transaction = Transaction.new
		@transaction.tx_date = @dateTx
		@transaction.posting_date = @dateTx
		@accounts = @user.account_selector

		@user.transactions << @transaction

		respond_to do |format|
			format.html # new.html.erb
			format.json {render json: @transaction}
		end
	end

	def destroy
		@user = current_user
		@transaction = @user.transactions.find(params[:id])
		@transaction.destroy

		respond_to do |format|
			format.html { redirect_back(fallback_location: root_path) }
			format.js   { render :nothing => true }
			format.json { head :ok }
		end
	end

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		category = params.has_key?(:category) ? params[:category].to_i : nil
		account = params.has_key?(:account) ? params[:account].to_i : nil

		@pagy, @transactions = pagy(@user.transactions
			.select("id, tx_date, credit, debit, tx_type, details, notes, acct_id_cr, acct_id_dr")
			.in_year(@year)
			.order(sort_column + ' ' + sort_direction))

		respond_to do |format|
			format.html #index.html.erb
			format.csv {}
		end
	end

	def new_attachment
		transaction_id = params.has_key?(:transaction_id) ? params[:transaction_id] : nil
		@transaction = Transaction.find(transaction_id)
		respond_to do |format|
			format.html
			format.js
		end
	end

	def update_attachment
		transaction_id = params.has_key?(:transaction_id) ? params[:transaction_id] : nil
		@transaction = Transaction.find(transaction_id) 
		@transaction.attachment.attach(params[:transaction][:attachment])
		respond_to do |format|
			format.html { redirect_back fallback_location: transactions_url }
			format.json { head :no_content }
		end
	end

	def delete_attachment
		transaction_id = params.has_key?(:transaction_id) ? params[:transaction_id] : nil
		transaction = Transaction.find(transaction_id)
		if transaction.attachment.attached?
			transaction.attachment.purge
		end

		respond_to do |format|
			format.html { redirect_back fallback_location: transactions_url }
			format.json { head :no_content }
		end
	end

	def uncategorized
		@user = current_user
		@tx_type = (params.has_key?(:tx_type) && params[:tx_type] == 'credit') ? 'credit' : 'debit'

		nullField = @tx_type == 'credit' ? 'acct_id_cr' : 'acct_id_dr'
		amountField = @tx_type == 'credit' ? "debit as 'amount'" : "credit as 'amount'"
		txTypeField = @tx_type == 'credit' ? "'credit' as 'txType'" : "'debit' as 'txType'"

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@month = params.has_key?(:month) ? params[:month].to_i : nil

		@pagy, @transactions = pagy(@user.transactions
			.select("id, tx_date, credit, debit, " + amountField + ", tx_type, details, notes, "\
				"acct_id_cr, acct_id_dr, parent_id, " + txTypeField + ", "\
				"(SELECT COUNT(*) from active_storage_attachments A WHERE A.record_id = transactions.id AND A.record_type = 'Transaction' and A.name = 'attachment' ) as attachments"
			)
			.where("(" + nullField + " IS NULL)")
			.in_month_year(@month, @year)
			.order(sort_column + ' ' + sort_direction))

		@display_type = @tx_type == 'credit' ? 'income' : 'expense'
		@title = "Uncategorized " + @display_type[0].capitalize + @display_type[1..-1] + " Transactions"

		respond_to do |format|
			format.html #index.html.erb
		end
	end

	private

	def transaction_params
		params.require(:transaction).permit(:name, :description, :account_type, :year, :id, :credit, :acct_id_dr, :debit, :tx_type, :details, :notes, :acct_id_cr, :tx_date, :posting_date)
	end

end
