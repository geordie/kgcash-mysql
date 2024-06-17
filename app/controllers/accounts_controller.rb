class AccountsController < ApplicationController

	def index

		@user = current_user

		accounts = @user.accounts.importable

		@accounts_array = Array.new(0)

		accounts.each do |a|
			transactions = Transaction.all.in_account(a.id).order(:tx_date)
			tx_count = transactions.count

			hashAccountInfo = Hash.new

			hashAccountInfo["account"] = a
			hashAccountInfo["tx_count"] = tx_count

			if tx_count > 0
				hashAccountInfo["tx_first"] = transactions[0].tx_date
				hashAccountInfo["tx_last"] = transactions[tx_count-1].tx_date
			end

			@accounts_array.push(hashAccountInfo)
		end

		@allAccounts = @user.sortedAccounts
		@expenseAccounts = @user.accounts.expense
		@incomeAccounts = @user.accounts.income
		@assetAccounts = @user.accounts.asset
		@liabilityAccounts = @user.accounts.liability

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
		params.require(:account).permit(:name, :description, :account_type, :import_class)
	end

end
