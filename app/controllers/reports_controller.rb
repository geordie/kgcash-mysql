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

		if @month.nil?
			@months = time.month
			@days = time.mday - 1
			@budget_categories.each do |bud_cat|
				@bud_cat_amount = bud_cat.amount.nil? ? 0 : bud_cat.amount
				@new_amount = (@bud_cat_amount * @months) + (@bud_cat_amount * (@days/30))
				bud_cat.amount = @new_amount
		 	end
		end

		# Get transactions by category
		if @month.nil?
			@transactions_grouped = @user.transactions
				.select("SUM(transactions.credit) - SUM(transactions.debit) as amount, categories.name AS category_name, categories.cat_type as category_type")
				.joins(:category)
				.group("categories.id")
				.in_year( @year)
		elsif
			@transactions_grouped = @user.transactions
				.select("SUM(transactions.credit) - SUM(transactions.debit) as amount, categories.name AS category_name, categories.cat_type as category_type")
				.joins(:category)
				.group("categories.id")
				.in_month_year( @month, @year)
		end

		respond_to do |format|
			format.html #index.html.erb
			format.json {render json: @transactions_grouped }
		end
	end

end