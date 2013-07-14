class ReportsController < ApplicationController
	 
	doorkeeper_for :all, :if => lambda { current_user.nil? && request.format.json? } 
	
	def index
		@user = current_user
		if @user == nil 
			@user = User.last
		end 

		#TODO - Enable filtering by date range
		time = Time.new
		@month = params.has_key?(:month) ? params[:month].to_i : nil
		@year = params.has_key?(:year) ? params[:year].to_i : time.year

		if @month.nil?
			@transactions = @user.transactions
				.select("transactions.*, categories.name AS category_name, categories.cat_type as category_type")
				.joins(:category)
				.in_year( @year)
		elsif
			@transactions = @user.transactions
				.select("transactions.*, categories.name AS category_name, categories.cat_type as category_type")
				.joins(:category)
				.in_month_year( @month, @year)
		end

		@tx_by_month_in_year = @user.transactions.by_months_in_year( @year )

		@expense_categories = Hash.new
		@income_categories = Hash.new
		
		@totalExpense = 0
		@totalIncome = 0

		puts @transactions.to_json

		@transactions.each do |t|

			next unless t.category_type == "Expense" || t.category_type == "Income" || t.category_type.nil?
			next if t.category_name == "Not defined"

			if t.category_type == "Expense" || t.category_type.nil? 
				@amountExpense = -1 * (t.credit.nil? ? 0 : t.credit) + (t.debit.nil? ? 0 : t.debit)
				@totalExpense += @amountExpense;

				if @expense_categories.has_key? t.category_name
					@expense_categories[ t.category_name ] += @amountExpense
				else
					@expense_categories[ t.category_name ] = @amountExpense
				end
				
			elsif t.category_type == "Income"
				@amountIncome = (t.credit.nil? ? 0 : t.credit) + -1 * (t.debit.nil? ? 0 : t.debit)
				@totalIncome += @amountIncome;
				
				if @income_categories.has_key? t.category_name
					@income_categories[ t.category_name ] += @amountIncome
				else
					@income_categories[ t.category_name ] = @amountIncome
				end
			end
		end

		# Use this format because it's nice for D3 JSON - maybe should do this client side instead, but whatev
		@category_amounts = Array.new

		@expense_categories.each_pair do |key,val|
			@category_amounts.push( CategoryAmount.new( key, val ))
		end

		@category_amounts.sort!{|a,b| b.amount <=> a.amount}

		@category_income = Array.new

		@income_categories.each_pair do |key,val|
			@category_income.push( CategoryAmount.new( key, val ))
		end

		@category_income.sort!{|a,b| b.amount <=> a.amount}

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