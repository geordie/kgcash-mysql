class ExpensesController < ApplicationController
	include TransactionControllerConcern

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@month = params.has_key?(:month) ? params[:month].to_i : nil
		@category = params.has_key?(:category) ? params[:category].to_i : nil

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
			.in_account( @category )
			.in_month_year(@month, @year)
			.order(sort_column + ' ' + sort_direction))

		if !@category.nil?
			cat = @user.accounts.find(@category)
			if !cat.nil?
				@category_name = cat.name
			end
		end

		# Get the accounts that could have been used to spend in this category
		@accountTotals = Hash.new()
		accounts_importable = @user.accounts.importable

		accounts_importable.each do |acct_importable|
			@accountTotals[acct_importable.id] = [acct_importable.name, 0]
		end

		# Build a total value spent on the category per account
		if !@category.nil?
			total = 0
			@transactions.each do |t|
				if t.acct_id_dr == @category
					acct = Account.find(t.acct_id_cr)
					if @accountTotals.has_key?(t.acct_id_cr)
						@accountTotals[t.acct_id_cr][1] += t.debit
					else
						@accountTotals[t.acct_id_cr] = [acct.name, t.debit]
					end
					total += t.debit
				else
					acct = Account.find(t.acct_id_dr)
					if @accountTotals.has_key?(t.acct_id_dr)
						@accountTotals[t.acct_id_dr][1] -= t.credit
					else
						@accountTotals[t.acct_id_dr] = [acct.name, t.credit * -1]
					end
					total -= t.debit
				end
			end
			@accountTotals[-1] = ["Total", total]
		end

		respond_to do |format|
			format.html #index.html.erb
			format.csv {}
		end
	end

	def uncategorized
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@month = params.has_key?(:month) ? params[:month].to_i : nil

		@pagy, @transactions = pagy(@user.transactions
			.select("id, tx_date, credit, credit as 'amount', debit, tx_type, details, notes, acct_id_cr, acct_id_dr, parent_id, 'debit' as 'txType'")
			.is_expense()
			.where("(acct_id_dr IS NULL)")
			.in_month_year(@month, @year)
			.order(sort_column + ' ' + sort_direction))

		respond_to do |format|
			format.html #index.html.erb
			format.csv {}
		end
	end

	def split
		@id = params.has_key?(:id) ? params[:id].to_i : 0

		@user = current_user

		@transaction = @user.transactions.find(@id)
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

		@transaction_list = [@transaction, @transaction_new]

		respond_to do |format|
			format.html
		end
	end

	def split_commit

		user = current_user

		# Get the base transaction
		base_tx_id = params[:tx_id]
		base_transaction = user.transactions.find(base_tx_id)

		# Get the transactions to commit
		transactions = params[:transactions]

		transactions.each do |transaction|
			tx_id = transaction[0]
			tx_params = transaction[1]
			amount_new = tx_params[:credit].gsub(/[^\d\.-]/,'').to_f

			if user.transactions.exists? tx_id

				# Find the existing transaction
				tx_existing = user.transactions.find(tx_id)

				# Modify values for the split transaction
				tx_existing.debit = amount_new
				tx_existing.credit = amount_new
				tx_existing.acct_id_dr = tx_params[:acct_id_dr]
				tx_existing.notes = tx_params[:notes]
				tx_existing.parent_id = base_transaction.id

				# Copy attachment if there is one
				if base_transaction.attachment.attached?
					tx_existing.attachment.attach \
					:io           => StringIO.new(base_transaction.attachment.download),
					:filename     => base_transaction.attachment.filename,
					:content_type => base_transaction.attachment.content_type
				end

				# Update the transaction hash
				tx_existing.tx_hash = tx_existing.build_hash

				#Save
				tx_existing.save
			else
				# Copy attribute values from the base transaction
				tx_new = Transaction.new(base_transaction.attributes.slice(*Transaction.attribute_names))

				# Modify values for the split transaction
				tx_new.id = nil
				tx_new.debit = amount_new
				tx_new.credit = amount_new
				tx_new.acct_id_dr = tx_params[:acct_id_dr]
				tx_new.notes = tx_params[:notes]
				tx_new.parent_id = base_transaction.id
				tx_new.created_at = Time.now

				# Copy attachment if there is one
				if base_transaction.attachment.attached?
					tx_new.attachment.attach \
					:io           => StringIO.new(base_transaction.attachment.download),
					:filename     => base_transaction.attachment.filename,
					:content_type => base_transaction.attachment.content_type
				end

				# Update the transaction hash
				tx_new.tx_hash = tx_new.build_hash

				# Save
				tx_new.save
			end
		end

		respond_to do |format|
			format.html { redirect_to(transaction_path(:id => base_tx_id)) }
		end
	end

	def update
	end

	private

	def expense_params
		params.require(:transaction).permit(:name, :description, :account_type, :year, :id, :credit, :debit, :acct_id_dr, :tx_type, :details, :notes, :acct_id_cr, :tx_date, :posting_date, :items)
	end

end
