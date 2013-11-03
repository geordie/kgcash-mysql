class ReportsController < ApplicationController
	 
	doorkeeper_for :all, :if => lambda { current_user.nil? && request.format.json? } 
	
	def index
		@user = current_user
		if @user == nil 
			@user = User.last
		end 

		@budget_categories = @user.budgets[0].budget_categories

		#TODO - Enable filtering by date range
		time = Time.new
		@month = params.has_key?(:month) ? params[:month].to_i : nil
		@year = params.has_key?(:year) ? params[:year].to_i : time.year

		if @month.nil?
			@transactions = @user.transactions
				.select("transactions.*, categories.name AS category_name, categories.cat_type as category_type")
				.joins(:category)
				.in_year( @year)

			@transactions_grouped = @user.transactions
				.select("SUM(transactions.debit) + SUM(transactions.credit) as amount, categories.name AS category, categories.cat_type as category_type")
				.joins(:category)
				.group("categories.id")
				.in_year( @year)
		elsif
			@transactions = @user.transactions
				.select("transactions.*, categories.name AS category_name, categories.cat_type as category_type")
				.joins(:category)
				.in_month_year( @month, @year)

			@transactions_grouped = @user.transactions
				.select("SUM(transactions.debit) + SUM(transactions.credit) as amount, categories.name AS category_name, categories.cat_type as category_type")
				.joins(:category)
				.group("categories.id")
				.in_month_year( @month, @year)
		end
		
		@totalExpense = 0
		@totalIncome = 0

		@transactions_grouped.each do |t|

			next unless t.category_type == "Expense" || t.category_type == "Income" || t.category_type.nil?

			if t.category_type == "Expense" || t.category_type.nil? 
				@totalExpense += t.amount;
				
			elsif t.category_type == "Income"
				@totalIncome += t.amount;
			end
		end

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @expense_categories }
		end
	end

end

class CategoryAmount
	attr_accessor :category, :amount

	def initialize(category, amount)
	@category = category
	@amount = amount
	end      
end