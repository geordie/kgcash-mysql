class AccountsController < ApplicationController

	def index

		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		@expenseAccounts = @user.accounts.expense.order(:name)
		@incomeAccounts = @user.accounts.income.order(:name)
		@assetAccounts = @user.accounts.asset.order(:name)
		@liabilityAccounts = @user.accounts.liability.order(:name)

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @accounts }
		end
	end

	def spending

		@user = current_user

		accounts = @user.accounts.importable

		@accounts_array = Array.new(0)

		accounts.each do |a|
			transactions = Transaction.select("min(tx_date) as tx_first, max(tx_date) as tx_last, count(*) as tx_count")
				.where("acct_id_dr = " + a.id.to_s + " OR acct_id_cr = " + a.id.to_s )

			accountInfo = nil
			unless transactions.nil? or transactions.length < 0
				accountInfo = transactions[0]

				hashAccountInfo = {
					"account" => a,
					"tx_count" => accountInfo.tx_count,
				}

				if accountInfo.tx_count > 0
					hashAccountInfo["tx_first"] = accountInfo.tx_first
					hashAccountInfo["tx_last"] = accountInfo.tx_last
				end

				@accounts_array << hashAccountInfo
			end
		end

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @accounts }
		end
	end

	def edit
		@user = current_user
		@account = @user.accounts.find(params[:id])
	end

	def create
		@user = current_user
		@account = @user.accounts.create(account_params)

		respond_to do |format|
			if @account.save
				format.html { redirect_to(accounts_path, :notice => 'Account was successfully created for user.') }
				format.json { render json: @account, status: :created, location: @account }
			else
				format.html { render action: "new" }
				format.json { render json: @account.errors, status: :unprocessable_entity }
			end
		end
	end

	def show
		@user = current_user

		@account = @user.accounts.find(params[:id])

		debits_monthly = @account.debits_monthly
		credits_monthly = @account.credits_monthly

		# chart data structure
		barData = Array.new(0)
		barDataDebits = {name: "Debits", values: Array.new(0)}
		barDataCredits = {name: "Credits", values: Array.new(0)}
		barDataBalance = {name: "Balance", values: Array.new(0)}

		# table data structure
		@monthly_balance = Array.new(0)

		(1..12).each do |month|

			monthHash = {month: Date::MONTHNAMES[month][0..2]}

			monthDebit = 0
			if debits_monthly.has_key?(month)
				monthDebit = debits_monthly[month]
			end

			barDataDebits[:values] << monthDebit
			monthHash[:debits] = monthDebit

			monthCredit = 0
			if credits_monthly.has_key?(month)
				monthCredit = credits_monthly[month]
			end

			monthHash[:credits] = monthCredit
			barDataCredits[:values] << monthCredit

			monthHash[:balance] = (monthCredit - monthDebit).abs
			barDataBalance[:values] << (monthCredit - monthDebit).abs

			@monthly_balance << monthHash
		end

		gon.echart = barData << barDataDebits << barDataCredits << barDataBalance

		respond_to do |format|
			format.html #show.html.erb
			format.json {render json: @account}
		end
	end

	def update
		@account = Account.find(params[:id])

		respond_to do |format|
			if @account.update(account_params)
				format.html { redirect_to accounts_path, notice: 'Account was successfully updated.' }
				format.json { respond_with_bip(@account) }
				format.js {render :nothing => true }
			else
				format.html { render action: "edit" }
				format.json { render json: @account.errors, status: :unprocessable_entity }
			end
		end
	end

	def new
		@user = current_user
		@account = Account.new

		respond_to do |format|
			format.html # new.html.erb
			format.json {render json: @account}
		end
	end

	def destroy
		@user = current_user
		@account = @user.accounts.find(params[:id])
		@account.destroy

		respond_to do |format|
			format.html { redirect_to :action => 'index' }
			format.js   { render :nothing => true }
			format.json { head :ok }
		end
	end

	private

	def account_params
		params.require(:account).permit(:name, :description, :account_type, :import_class, :year)
	end

end
