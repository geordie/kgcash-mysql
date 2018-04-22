class ReportsController < ApplicationController

	def index

		# Get user
		@user = current_user

		# Get budget
		@budget_categories = @user.budgets[0].budget_categories

		# Set date range
		#TODO - Enable filtering by date range
		time = Time.new
		month = params.has_key?(:month) ? params[:month].to_i : nil
		@year = params.has_key?(:year) ? params[:year].to_i : time.year

		@account = params.has_key?(:account) ? params[:account].to_i : nil
		if @account && @account < 1
			@account = nil
		end

		if month.nil?
			@months = time.month
			budgeted_amount_multiplier = time.year == @year ? @months : 12
			@budget_categories.each do |bud_cat|
				bud_cat_amount = bud_cat.amount.nil? ? 0 : bud_cat.amount
				new_amount = (bud_cat_amount * budgeted_amount_multiplier)
				bud_cat.amount = new_amount
			end
		end

		@transactions_income = @user.transactions
			.joins( "LEFT JOIN accounts ON accounts.id = transactions.acct_id_cr")
			.select("sum(credit) as credit, sum(debit) as debit, accounts.name, acct_id_cr")
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset' or account_type = 'Expense'))")
			.where("(acct_id_cr IS NULL or acct_id_cr in (select id from accounts where account_type = 'Income'))")
			.in_year(@year)
			.group("acct_id_cr")

		@transactions_expenses = @user.transactions
			.joins( "LEFT JOIN accounts ON accounts.id = transactions.acct_id_dr")
			.select("sum(credit) as credit, sum(debit) as debit, accounts.name, acct_id_dr")
			.where("(acct_id_cr in (select id from accounts where account_type = 'Liability' or account_type = 'Asset'))")
			.where("(acct_id_dr IS NULL or acct_id_dr in (select id from accounts where account_type = 'Expense'))")
			.in_year(@year)
			.group("acct_id_dr")

		category_income = Array.new
		category_expenses = Array.new
		category_undefined = Array.new
		category_savings = Array.new

		income_credit = 0
		expenses_credit = 0
		income_undefined = 0
		expenses_undefined = 0

		@transactions_expenses.each do |tg_expense|
			if !tg_expense.acct_id_dr.nil?
				category_expenses << tg_expense
				tg_expense.category_id = tg_expense.acct_id_dr
				expenses_credit += tg_expense.credit
			else
				expenses_undefined += tg_expense.credit
			end
		end

		@transactions_income.each do |tg_income|
			if !tg_income.acct_id_cr.nil?
				category_income << tg_income
				tg_income.category_id = tg_income.acct_id_cr
				income_credit += tg_income.credit
			else
				income_undefined += tg_income.debit
			end
		end

		@category_groups = Hash[
			"total_income" => income_credit,
			"total_expenses" => expenses_credit,
			"Income" => category_income,
			"Expense" => category_expenses,
			"undefined_income" => income_undefined,
			"undefined_expenses" => expenses_undefined]

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @category_groups }
		end
	end

	def category

		# Get week specified
		today = Date.today
		year = params.has_key?(:year) ? params[:year].to_i : today.year

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

		@account = params.has_key?(:account) ? params[:account].to_i : nil
		if @account && @account < 1
			@account = nil
		end

		@months = time.month
		@total_months = time.year == year ? @months : 12

		@transaction_groups = nil
		# Get transactions by category
		@transaction_groups = @user.transactions
			.in_account(@account)
			.select('category_id, count(transactions.debit) as count,
				month(transactions.tx_date) as month,
				SUM(transactions.credit) - SUM(transactions.debit) as amount,
				categories.name AS category_name, categories.cat_type as category_type')
			.joins(:category)
			.group('categories.id, month(transactions.tx_date)')
			.in_year( year)

		######################
		# This section build for NVD3 stacked bar chart

		category_array_expenses, @average_expense =
			build_nvd3_array( @transaction_groups, [nil,"Expense"], @total_months, method(:negative) )

		category_array_income, @average_income =
			build_nvd3_array( @transaction_groups, ["Income"], @total_months, method(:identity))

		category_array_savings, @average_savings =
			build_nvd3_array( @transaction_groups, ["Asset"], @total_months, method(:negative))

		gon.stacked1 = Array.new(1,category_array_expenses)
		gon.stacked1.push(category_array_income)
		gon.stacked1.push(category_array_savings)

		# End NVD3 section
		######################


		######################
		# This section builds for Dimple per category bar charts

		category_groups = Hash.new

		@transaction_groups.each do |transaction_group|

			if transaction_group.category_type == nil
				transaction_group.category_type = "Expense"
			end

			amount = transaction_group.amount
			if transaction_group.category_type == "Expense" || transaction_group.category_type == "Asset"
				amount = transaction_group.amount * -1
			end

			category_id = transaction_group.category_id
			if !category_groups.has_key?( category_id )
				category_groups[ category_id ] = Hash[
					"cat_id" => category_id,
					"cat_name" => transaction_group.category_name,
					"cat_type" => transaction_group.category_type,
					"values" => Array.new,
					"total" => 0,
					"count" => 0
				]
			end
			category_groups[ category_id ]["values"] << Hash[
				"month" => transaction_group.month,
				"amount" => amount
			]
			category_groups[ category_id ]["count"] += transaction_group.count
			category_groups[ category_id ]["total"] += amount

		end

		# fill out the each category group with months
		# for which there were not transactions
		active_months = (1..@total_months)
		category_groups.each do |cg_key, cg_value|

			# get an array of all active months
			months = active_months.to_a

			# subtract in-use months from the active months array
			cg_value["values"].each do |cat_month_value|
				months.delete(cat_month_value["month"])
			end

			# add any months that have no transactions
			months.each do |m|
				cg_value["values"] << Hash[
						"month" => m,
						"amount" => 0
				]
			end
		end

		@cats = category_groups.values

		respond_to do |format|
			format.html #category.html.erb
		end
	end

	def income

		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@quantum = params.has_key?(:quantum) ? params[:quantum] : "month"

		sTimeAggregate = @quantum + "(tx_date)"

		sJoinsIncome = "LEFT JOIN accounts ON accounts.id = transactions.acct_id_cr"
		sJoinsExpense = "LEFT JOIN accounts ON accounts.id = transactions.acct_id_dr"

		sSelectIncome = sTimeAggregate + " as quantum, sum(debit) as debit, accounts.name, acct_id_cr"
		sSelectExpense = sTimeAggregate + " as quantum, sum(credit) as credit, accounts.name, acct_id_dr"

		sGroupByIncome = sTimeAggregate + ", acct_id_cr"
		sGroupByExpense = sTimeAggregate + ", acct_id_dr"

		sOrderByIncome = "acct_id_cr, " + sTimeAggregate
		sOrderByExpense = "acct_id_dr, " + sTimeAggregate

		@income = @user.transactions
			.joins( sJoinsIncome )
			.select( sSelectIncome )
			.is_liability()
			.where("(acct_id_cr in (select id from accounts where account_type = 'Income'))")
			.in_year(@year)
			.group( sGroupByIncome )
			.order( sOrderByIncome )

		@expense = @user.transactions
			.joins( sJoinsExpense )
			.select(sSelectExpense)
			.is_asset()
			.where("(acct_id_dr in (select id from accounts where account_type = 'Expense'))")
			.in_year(@year)
			.group( sGroupByExpense )
			.order( sOrderByExpense )

		gon.income = @income
		gon.expense = @expense

		respond_to do |format|
			format.html #income.html.erb
		end
	end

	private
	def build_nvd3_array( transaction_group, account_types, months, method_amount)
		category_hash = Hash.new()

		transaction_group.each do |tg|

			# Ensure transaction group is for a category whose type we're interested in
			next if !account_types.include? tg.category_type

			# Add a hash entry of a zeroed array if it doesn't already exist
			if !category_hash.key?(tg.category_name)
				category_hash[tg.category_name] = Array.new(months,0)
			end

			# Fill in the category amount for the month in the transaction group
			category_hash[tg.category_name][tg.month-1]=tg.amount
		end

		monthly_spend_array = Array.new(months,0)
		category_array = Array.new()

		category_hash.each do |k, v|

			array_category_monthly_values = Array.new(months)
			v.each_with_index do |item, item_index|
				array_category_monthly_values[item_index] = [item_index+1, method_amount.call(item.to_i)]
				monthly_spend_array[item_index] += method_amount.call(item.to_i)
			end

			# Build the NVD3 expected data structure
			category_hash_nvd3 = Hash.new()
			category_hash_nvd3["key"] = k
			category_hash_nvd3["values"] = array_category_monthly_values

			category_array.push(category_hash_nvd3)
		end

		total_spend = 0
		monthly_spend_array.each do |monthly_spend|
			total_spend += monthly_spend
		end
		average_spend = (total_spend/monthly_spend_array.size)

		return category_array, average_spend

	end

	def negative( amount )
		amount * -1
	end

	def identity( amount )
		amount
	end
end
