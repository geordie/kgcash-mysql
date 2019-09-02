class TransactionsController < ApplicationController

	helper_method :sort_column, :sort_direction

	def show

		@user = current_user
		if @user == nil
			@user = User.last
		end
		@transaction = @user.transactions.find(params[:id])

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
			if @transaction.update_attributes(transaction_params)
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
			#TODO Transactions index path no longer exists, so fix this next line
			format.html { redirect_to :action => 'index' }
			format.js   { render :nothing => true }
			format.json { head :ok }
		end
	end

	def index
		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		category = params.has_key?(:category) ? params[:category].to_i : nil
		account = params.has_key?(:account) ? params[:account].to_i : nil

		@transactions = @user.transactions
			.select("id, tx_date, credit, debit, tx_type, details, notes, acct_id_cr, acct_id_dr")
			.in_year(@year)
			.paginate(:page => params[:page])
			.order(sort_column + ' ' + sort_direction)

		respond_to do |format|
			format.html #index.html.erb
			format.csv {}
		end
	end

	private

	def sort_column
		['tx_date','account','details','notes','amount'].include?(params[:sort]) ? params[:sort] : "tx_date"
	end

	def sort_direction
		%w[asc desc].include?(params[:direction]) ?  params[:direction] : "desc"
	end

	def transaction_params
		params.require(:transaction).permit(:name, :description, :account_type, :year, :id, :credit, :acct_id_dr, :tx_type, :details, :notes, :acct_id_cr, :tx_date, :posting_date)
	end

end
