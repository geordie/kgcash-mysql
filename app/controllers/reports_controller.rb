class ReportsController < ApplicationController

	def index

		@user = current_user
		@year = params.has_key?(:year) ? params[:year].to_i : DateTime.now.year

		@account = params.has_key?(:account) ? params[:account].to_i : nil
		if @account && @account < 1
			@account = nil
		end

		@transactions_income = Transaction.income_by_category_OLD( @user, @year )

		@transactions_expenses = Transaction.expenses_by_category_OLD( @user, @year )

		category_income = Array.new
		category_expenses = Array.new

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

	def income

		@user = current_user
		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year

		@income = Transaction.income_by_category(@user, @year)
		gon.income = @income

		catSummaryIncome = CategorySummary.new( @income, "income", @year )
		gon.income2 = catSummaryIncome.values

		@expense = Transaction.expenses_by_category(@user, @year)
		gon.expense = @expense

		catSummaryExpense = CategorySummary.new( @expense, "expenses", @year )
		gon.expense2 = catSummaryExpense.values

		respond_to do |format|
			format.html #income.html.erb
		end
	end

	def spend

		@user = current_user
		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@month = params.has_key?(:month) ? params[:month].to_i : Date.today.month

		@spending = Transaction.spend_over_time(@user, @year, @month)

		first_day = DateMath.first_day_of_month_ordinal(@year,@month)
		last_day = DateMath.last_day_of_month_ordinal(@year,@month)

		firstItem = @spending.first.as_json

		results = Array.new(last_day - first_day+1)

		j = 0
		for i in first_day..last_day do

			existingItem = @spending.where(:xValue == 1).first.as_json
			if existingItem
				results[j] = existingItem.clone()
			else
				newItem = firstItem.clone()
				newItem[:xCategory] = Date.ordinal(@year,i).strftime("%Y-%m-%d")
				newItem[:xValue] = i
				newItem[:expenses] = 0
				results[j] = newItem
			end
			j = j+1
		end

		gon.spending = results

		respond_to do |format|
			format.html #spend.html.erb
		end
	end

	def alltime
		@user = current_user

		expenses = Transaction.expenses_all_time(@user)
		uncategorized_expenses = Transaction.uncategorized_expenses(@user)
		revenues = Transaction.revenues_all_time(@user)
		uncategorized_revenue = Transaction.uncategorized_revenue(@user)

		# Merge results into one data structure, indexed on year
		results_tmp = Hash.new

		# Add expenses for each year
		expenses.each do |item|
			results_tmp[item.year] = {"year"=>item.year,:expenses=>item.expenses}
		end

		# Add uncategorized expenses for each year
		uncategorized_expenses.each do |item|
			results_tmp[item.year]["uncategorized_expenses"] = item.uncategorized_expenses
		end

		# Add revenue for each year
		revenues.each do |item|
			results_tmp[item.year]["revenue"] = item.revenue
		end

		# Add uncategorized revenue for each year
		uncategorized_revenue.each do |item|
			results_tmp[item.year]["uncategorized_revenue"] = item.uncategorized_revenue
		end

		@results = Array.new

		# Drop the year index used to map hashes, and add net revenue for each year
		results_tmp.each do |item|
			item[1]["net_revenue"] =
			item[1]["revenue"] +
			item[1]["uncategorized_revenue"] -
			item[1][:expenses] -
			item[1]["uncategorized_expenses"]
			# Drop the first item (the year index from result_tmp item)
			item.shift
			# Put the truncated item on the front of the results array
			# Note: this also reverses the order of the results (to year desc)
			@results.unshift(item)
		end

		respond_to do |format|
			format.html #alltime.html.erb
		end
	end
	
end
