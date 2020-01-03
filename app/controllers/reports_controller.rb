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

	def income

		@user = current_user

		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@quantum = params.has_key?(:quantum) ? params[:quantum] : "month"

		sTimeAggregate = @quantum + "(tx_date)"

		sJoinsIncomeA = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"
		sJoinsIncomeB = "LEFT JOIN accounts as accts_dr ON accts_dr.id = transactions.acct_id_dr"

		sJoinsExpenseA = "LEFT JOIN accounts as accts_cr ON accts_cr.id = transactions.acct_id_cr"
		sJoinsExpenseB = "LEFT JOIN accounts as accts_dr ON accts_dr.id = transactions.acct_id_dr"

		sSelectIncome = sTimeAggregate + " as quantum, "\
		"SUM(IF(accts_cr.account_type = 'Income', credit, debit*-1)) as 'income', "\
		"IF(accts_cr.account_type = 'Income', accts_cr.id, accts_dr.id) as acct_id, "\
		"IF(accts_cr.account_type = 'Income', accts_cr.name, accts_dr.name) as name"

		sSelectExpense = sTimeAggregate + " as quantum, "\
		"SUM(IF(accts_dr.account_type = 'Expense', debit, credit*-1)) as 'expenses', "\
		"IF(accts_dr.account_type = 'Expense', accts_dr.id, accts_cr.id) as acct_id, "\
		"IF(accts_dr.account_type = 'Expense', accts_dr.name, accts_cr.name) as name"

		sGroupByIncome = sTimeAggregate + ", IF(accts_cr.account_type = 'Income', accts_cr.id, accts_dr.id),"\
		"IF(accts_cr.account_type = 'Income', accts_cr.name, accts_dr.name)"
		
		sGroupByExpense = sTimeAggregate + ", IF(accts_dr.account_type = 'Expense', accts_dr.id, accts_cr.id),"\
		"IF(accts_dr.account_type = 'Expense', accts_dr.name, accts_cr.name)"

		sOrderByExpense = "acct_id_dr, " + sTimeAggregate

		@income = @user.transactions
			.joins( sJoinsIncomeA )
			.joins( sJoinsIncomeB )
			.select( sSelectIncome )
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset') "\
				"AND acct_id_cr in (select id from accounts where account_type = 'Income')) "\
					"OR "\
				"(acct_id_cr in (select id from accounts where account_type = 'Asset') "\
				"AND acct_id_dr in (select id from accounts where account_type = 'Income'))")
			.in_year(@year)
			.group( sGroupByIncome )
			.order( sTimeAggregate )

		gon.income = @income

		catSummaryIncome = CategorySummary.new( @income, "income" )
		gon.income2 = catSummaryIncome.values

		@expense = @user.transactions
			.joins( sJoinsExpenseA )
			.joins( sJoinsExpenseB )
			.select(sSelectExpense)
			.where("(acct_id_dr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
				"AND acct_id_cr in (select id from accounts where account_type = 'Expense')) "\
					"OR "\
				"(acct_id_cr in (select id from accounts where account_type = 'Asset' or account_type = 'Liability') "\
				"AND acct_id_dr in (select id from accounts where account_type = 'Expense'))")
			.in_year(@year)
			.group( sGroupByExpense )
			.order( sTimeAggregate )

		gon.expense = @expense

		catSummaryExpense = CategorySummary.new( @expense, "expenses" )
		gon.expense2 = catSummaryExpense.values

		respond_to do |format|
			format.html #income.html.erb
		end
	end
	
end
