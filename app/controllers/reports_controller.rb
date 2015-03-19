class ReportsController < ApplicationController
	 
	doorkeeper_for :all, :if => lambda { current_user.nil? && request.format.json? } 
	
	def index

		# Get user
		@user = current_user
		if @user == nil 
			@user = User.last
		end 

		# Get budget
		@budget_categories = @user.budgets[0].budget_categories

		# Set date range
		#TODO - Enable filtering by date range
		time = Time.new
		@month = params.has_key?(:month) ? params[:month].to_i : nil
		@year = params.has_key?(:year) ? params[:year].to_i : time.year

		@account = params.has_key?(:account) ? params[:account].to_i : nil
		if @account && @account < 1
			@account = nil
		end

		if @month.nil?
			@months = time.month
			budgeted_amount_multiplier = time.year == @year ? @months : 12
			@budget_categories.each do |bud_cat|
				bud_cat_amount = bud_cat.amount.nil? ? 0 : bud_cat.amount
				new_amount = (bud_cat_amount * budgeted_amount_multiplier)
				bud_cat.amount = new_amount
			end
		end

		transaction_groups = nil
		# Get transactions by category
		if @month.nil?
			transaction_groups = @user.transactions
				.in_account(@account)
				.select('category_id, SUM(transactions.credit) - SUM(transactions.debit) as amount, categories.name AS category_name, categories.cat_type as category_type')
				.joins(:category)
				.group('categories.id')
				.in_year( @year)
		else
			transaction_groups = @user.transactions
				.in_account(@account)
				.select('category_id, SUM(transactions.credit) - SUM(transactions.debit) as amount, categories.name AS category_name, categories.cat_type as category_type')
				.joins(:category)
				.group('categories.id')
				.in_month_year( @month, @year)
		end

		category_income = Array.new
		category_expenses = Array.new
		category_undefined = Array.new
		category_savings = Array.new

		total_income = 0
		total_expenses = 0
		total_savings = 0
		total_undefined = 0

		transaction_groups.each do |transaction_group|
			if transaction_group.category_name == "Not defined"
				category_undefined << transaction_group
				total_undefined += transaction_group.amount
			elsif transaction_group.amount > 0
				category_income << transaction_group
				total_income += transaction_group.amount
			elsif transaction_group.category_type == "Asset"
				category_savings << transaction_group
				total_savings += transaction_group.amount * -1
			else
				category_expenses << transaction_group
				total_expenses += transaction_group.amount * -1
			end

			# Splice in the budgeted amount
			budget_category = @budget_categories.find{|item| item["category_id"] ==
					transaction_group.category_id}

			transaction_group["budget"] = budget_category.amount

			# Set a default category type
			if transaction_group.category_type == nil
				transaction_group.category_type = "Expense"
			end

			if transaction_group.category_type == "Expense" || transaction_group.category_type == "Asset"
				transaction_group.amount = transaction_group.amount * -1
			end
		end

		@category_groups = Hash[
			"total_income" => total_income,
			"total_expenses" => total_expenses,
			"Income" => category_income,
			"Expense" => category_expenses,
			"Asset" => category_savings,
			"Undefined" => category_undefined]

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @category_groups }
		end
	end

end