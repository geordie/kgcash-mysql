class TransactionsController < ApplicationController

	doorkeeper_for :all, :if => lambda { current_user.nil? && request.format.json? }

	helper_method :sort_column, :sort_direction
	
	def index

		@user = current_user
		if @user == nil 
			@user = User.last
		end 

		time = Time.new
		@month = params.has_key?(:month) ? params[:month].to_i : nil
		@year = params.has_key?(:year) ? params[:year].to_i : time.year

		@category = params.has_key?(:category) ? params[:category].to_i : nil
		if @category && @category < 1 
			@category = nil
		end

		@account = params.has_key?(:account) ? params[:account].to_i : nil
		if @account && @account < 1
			@account = nil
		end

		if @month.nil?
			@transactions = @user.transactions
				.select("*, (debit + credit) as amount")
				.in_account(@account).in_category(@category)
				.in_year(@year)
				.order(sort_column + ' ' + sort_direction)
		elsif
			@transactions = @user.transactions
				.select("*, (debit + credit) as amount")
				.order(sort_column + ' '  + sort_direction)
				.in_account(@account).in_category(@category)
				.in_month_year(@month,@year)
				.order(sort_column + ' ' + sort_direction)
		end

		@budgets = @user.budgets

		#TODO - Enable filtering by date range
		# dateStart = params Date.strptime([:start], "{ %Y, %m, %d }")
		# dateEnd = params[:end]

		respond_to do |format|
			format.html #index.html.erb
			format.json { @transactions }
			format.csv {}
		end
	end

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
		@categories = @user.category_selector
		@accounts = @user.account_selector
	end

	def create
		@user = current_user
		if @user == nil 
			@user = User.last
		end 
		@transaction = @user.transactions.create(params[:transaction])

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
		@transaction = Transaction.find(params[:id])

		respond_to do |format|
			if @transaction.update_attributes(params[:transaction])
			format.html { redirect_to transactions_path, notice: 'Transaction was successfully updated.' }
			format.json { respond_with_bip(@transaction) }
			format.js {render :nothing => true }
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
		@categories = @user.category_selector
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
			format.html { redirect_to :action => 'index' }
			format.js   { render :nothing => true }
			format.json { head :ok }
		end
	end

	private

	def sort_column
		['tx_date','account','details','notes','amount'].include?(params[:sort]) ? params[:sort] : "tx_date"
	end

	def sort_direction
		%w[asc desc].include?(params[:direction]) ?  params[:direction] : "desc"
	end

end
