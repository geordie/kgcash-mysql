class ReportsController < ApplicationController

	def index
		@user = current_user

		respond_to do |format|
			format.html #index.html.erb
		end
	end

	def income

		year_current = Date.today.year

		@user = current_user
		@year = params.has_key?(:year) ? [params[:year].to_i , year_current].min : year_current

		income = Transaction.income_by_category(@user, @year)
		catSummaryIncome = CategorySummary.new( income, "income", @year )
		gon.income2 = catSummaryIncome.values

		expense = Transaction.expenses_by_category(@user, @year)
		catSummaryExpense = CategorySummary.new( expense, "expenses", @year )
		gon.expense2 = catSummaryExpense.values

		respond_to do |format|
			format.html #income.html.erb
		end
	end

	def cashflow

		@user = current_user
		@year = params.has_key?(:year) ? params[:year].to_i : Date.today.year
		@month = params.has_key?(:month) ? params[:month].to_i : nil

		@income_array = Transaction.income_by_account(@user, @year, @month)

		@cash_spend_array = Transaction.cash_spend_by_account(@user, @year, @month)

		@credit_spend_array = Transaction.credit_spend_by_account(@user, @year, @month)

		respond_to do |format|
			format.html #cashflow.html.erb
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
			results_tmp[item.year] = {:year=>item.year,:expenses=>item.expenses}
		end

		# Add uncategorized expenses for each year
		uncategorized_expenses.each do |item|
			if !results_tmp.include? item.year
				results_tmp[item.year] = {:year=>item.year}
			end
			results_tmp[item.year][:uncategorized_expenses] = item.uncategorized_expenses
		end

		# Add revenue for each year
		revenues.each do |item|
			if !results_tmp.include? item.year
				results_tmp[item.year] = {:year=>item.year}
			end
			results_tmp[item.year][:revenue] = item.revenue
		end

		# Add uncategorized revenue for each year
		uncategorized_revenue.each do |item|
			if !results_tmp.include? item.year
				results_tmp[item.year] = {:year=>item.year}
			end
			results_tmp[item.year][:uncategorized_revenue] = item.uncategorized_revenue
		end

		# Fill in any blanks
		results_tmp.each do |item|
			if item[1][:expenses].nil?
				item[1][:expenses] = 0
			end
			if item[1][:uncategorized_expenses].nil?
				item[1][:uncategorized_expenses] = 0
			end
			if item[1][:revenue].nil?
				item[1][:revenue] = 0
			end
			if item[1][:uncategorized_revenue].nil?
				item[1][:uncategorized_revenue] = 0
			end
		end

		@results = Array.new

		# Drop the year index used to map hashes, and add net revenue for each year
		results_tmp.each do |item|
			item[1][:net_revenue] =
			item[1][:revenue] +
			item[1][:uncategorized_revenue] -
			item[1][:expenses] -
			item[1][:uncategorized_expenses]
			# Drop the first item (the year index from result_tmp item)
			item.shift
			# Put the truncated item on the front of the results array
			# Note: this also reverses the order of the results (to year desc)
			@results.unshift(item)
		end

		respond_to do |format|
			format.html #alltime.html.erb
			format.pdf do
				pdf = Prawn::Document.new
				pdf.text "Prawn World!"
				send_data pdf.render,
				filename: "export.pdf",
				type: 'application/pdf',
				disposition: 'inline'
			end
		end
	end

	def alltime_expenses
		@user = current_user

		@results = Array.new

		expenses = Transaction.expenses_by_category(@user)

		echart = transform_to_echart( expenses, "expenses" )

		gon.echart = echart

		respond_to do |format|
			format.html #alltime.html.erb
		end
	end

	def alltime_revenue
		@user = current_user

		@results = Array.new

		revenue = Transaction.income_by_category(@user)

		echart = transform_to_echart( revenue, "income" )

		gon.echart = echart

		respond_to do |format|
			format.html #alltime.html.erb
		end
	end

	private

	def transform_to_echart( data, valField )

		data_echart = Hash.new();
		seriesArray = Array.new();
		dataObj = Hash.new();
		xAxis = Array.new();
		minQuantum = 1000000
		maxQuantum = 0

		data.each do |item,i|

			# X-Axis work
			# Get the name of the X-axis category
			xCategory = item.xCategory
			# Shift min and max if needed based on current value
			minQuantum = [xCategory.to_i ,minQuantum].min
			maxQuantum = [xCategory,maxQuantum].max

			# Y-Axis work
			# Get the name of the series
			series = item.name
			# Get the value of the series
			value = item[valField]

			# Add the series to a temp data structure if doesn't exist
			if !dataObj.has_key?(series)
				dataObj[series] = Hash.new()
				dataObj[series]["data"] = Array.new()
			end

			# Set the series value in the temp object
			dataObj[series]["data"][xCategory] = value.to_f
		end

		dataObj.keys.each do |dataKey|

			# Fill in any blanks in the temp data structure
			(minQuantum..maxQuantum).each do |i|
				if dataObj[dataKey]["data"][i].nil?
					dataObj[dataKey]["data"][i] = 0
				end
			end

			entry = {"name":dataKey,"type":'bar',"stack":"dollars","data":dataObj[dataKey]["data"].slice(minQuantum,maxQuantum-1)};
			seriesArray.push(entry);
		end

		# Build xAxis
		(minQuantum..maxQuantum).each do |i|
			xAxis.push(i)
		end

		# Populate the echart options data structure
		data_echart["series"] = seriesArray;
		data_echart["xAxis"] = {"type":"category","data":xAxis};

		return data_echart;
	end
	
end
